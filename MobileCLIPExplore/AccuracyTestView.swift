import SwiftUI
import CoreLocation

// MARK: - 1. Test Result Data Model
struct TestResult: Identifiable {
    let id = UUID()
    let testPlace: TestPlace
    let predictions: [RankedPOICandidate]
    let isCorrect: Bool
    
    // 추가된 프로퍼티
    let originalRank: Int // JSON에 있던 기존 순위 (selectedIndex)
    let myNewRank: Int?   // 내가 만든 엔진의 새로운 순위 (0-based index)
}

// MARK: - 2. Accuracy Test ViewModel
@MainActor
class AccuracyTesterViewModel: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var isLoading = false
    @Published var progressMessage = "Ready to start accuracy test."
    @Published var overallAccuracy: Double = 0.0

    private let mobileCLIPClassifier = ZSImageClassification(model: defaultModel.factory())
    private let placesService = GooglePlacesAPIService()
    private var rankingEngine: POIRankingEngine {
        POIRankingEngine(classifier: mobileCLIPClassifier)
    }

    init() {
        Task { await mobileCLIPClassifier.load() }
    }

    func runAccuracyTest() async {
        isLoading = true
        progressMessage = "Loading test dataset..."
        testResults = []
        
        // 1. 테스트 파일 이름 변경
        guard let testDataSet = TestDataSetLoader.load(from: "top10_accuracy_inseo_2025-07-15") else {
            progressMessage = "Error: Failed to load 'top40...' JSON file. Make sure it's in the project target."
            isLoading = false
            return
        }

        var correctCount = 0
        let totalCount = testDataSet.places.count
        var tempResults: [TestResult] = []

        for (index, testPlace) in testDataSet.places.enumerated() {
            let photoUri = testPlace.cloudPhotos.first?.uri ?? ""
            progressMessage = "(\(index + 1)/\(totalCount)) Testing '\(testPlace.placeName)'..."

            guard let image = await loadImage(from: photoUri),
                  let pixelBuffer = image.toCVPixelBuffer() else {
                let result = TestResult(testPlace: testPlace, predictions: [], isCorrect: false, originalRank: testPlace.selectedIndex, myNewRank: nil)
                tempResults.append(result)
                self.testResults = tempResults
                continue
            }

            let photoCoordinate = CLLocationCoordinate2D(latitude: testPlace.location.latitude, longitude: testPlace.location.longitude)
            
            do {
                let categorizedPlaces = try await placesService.fetchAndCategorizePlaces(for: photoCoordinate)
                
                if categorizedPlaces.isEmpty {
                    let result = TestResult(testPlace: testPlace, predictions: [], isCorrect: false, originalRank: testPlace.selectedIndex, myNewRank: nil)
                    tempResults.append(result)
                    self.testResults = tempResults
                    continue
                }
                
                let placesToRank = categorizedPlaces.map { $0.place }

                let rankedCandidates = await rankingEngine.rankPlaces(
                    places: placesToRank,
                    imagePixelBuffer: pixelBuffer,
                    photoLocation: photoCoordinate
                )

                // 2. 순위 계산 및 TestResult 생성 로직 수정
                let top5Candidates = Array(rankedCandidates.prefix(5))
                let top5Names = top5Candidates.map { $0.place.name }
                let isCorrect = top5Names.contains(testPlace.placeName)

                if isCorrect { correctCount += 1 }

                let myRank = rankedCandidates.firstIndex { $0.place.name == testPlace.placeName }

                let result = TestResult(
                    testPlace: testPlace,
                    predictions: top5Candidates,
                    isCorrect: isCorrect,
                    originalRank: testPlace.selectedIndex,
                    myNewRank: myRank
                )
                
                tempResults.append(result)
                self.testResults = tempResults
                self.overallAccuracy = Double(correctCount) / Double(index + 1)

            } catch {
                print("An error occurred: \(error.localizedDescription)")
            }
        }

        overallAccuracy = totalCount > 0 ? (Double(correctCount) / Double(totalCount)) : 0.0
        progressMessage = "Test complete! Final Top-5 Accuracy: \(String(format: "%.2f", overallAccuracy * 100))%"
        isLoading = false
    }

    private func loadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
}

// MARK: - 3. Accuracy Test View
struct AccuracyTestView: View {
    @StateObject private var viewModel = AccuracyTesterViewModel()

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    if viewModel.isLoading {
                        ProgressView().padding(.bottom, 5)
                        Text(viewModel.progressMessage).font(.caption).multilineTextAlignment(.center)
                    } else {
                        Text(String(format: "Overall Accuracy: %.2f%%", viewModel.overallAccuracy * 100))
                            .font(.largeTitle).fontWeight(.bold)
                        Text(viewModel.progressMessage).font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding()

                List(viewModel.testResults) { result in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(result.isCorrect ? .green : .red)
                            VStack(alignment: .leading) {
                                Text("Answer").font(.caption).foregroundColor(.secondary)
                                Text(result.testPlace.placeName).fontWeight(.bold)
                            }
                        }
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("Original Rank").font(.caption2).foregroundColor(.gray)
                                Text("\(result.originalRank)").font(.title3).fontWeight(.medium)
                            }
                            
                            if let myRank = result.myNewRank {
                                let rankDifference = result.originalRank - (myRank + 1)
                                
                                Image(systemName: "arrow.right").font(.caption.weight(.bold)).foregroundColor(.gray)
                                
                                VStack(alignment: .leading) {
                                    Text("My Rank").font(.caption2)
                                        .foregroundColor(rankDifference > 0 ? .blue : (rankDifference < 0 ? .orange : .secondary))
                                    
                                    HStack {
                                        Text("\(myRank + 1)").font(.title3).fontWeight(.bold)
                                        
                                        if rankDifference > 0 {
                                            Image(systemName: "arrow.up.right.circle.fill").foregroundColor(.blue).font(.caption)
                                        } else if rankDifference < 0 {
                                            Image(systemName: "arrow.down.right.circle.fill").foregroundColor(.orange).font(.caption)
                                        }
                                    }
                                }
                            } else {
                                Text("(Not in rank list)").font(.caption).italic().foregroundColor(.red)
                            }
                        }
                        .padding(.leading, 38)

                        Text("My Top Predictions:").font(.caption).fontWeight(.semibold).padding(.top, 5)
                        if result.predictions.isEmpty {
                            Text("No predictions were made.").font(.subheadline).foregroundColor(.gray).italic()
                        } else {
                            ForEach(Array(result.predictions.enumerated()), id: \.element.id) { (index, candidate) in
                                HStack {
                                    Text("\(index + 1).").fontWeight(.medium)
                                    Text(candidate.place.name)
                                    Spacer()
                                    Text(String(format: "%.3f", candidate.finalScore))
                                        .font(.system(.body, design: .monospaced)).fontWeight(.semibold)
                                }
                                .font(.subheadline).padding(8)
                                .background((candidate.place.name == result.testPlace.placeName) ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(.plain)
                
                Button(action: { Task { await viewModel.runAccuracyTest() } }) {
                    Text("Start Accuracy Test").fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                        .background(viewModel.isLoading ? Color.gray : Color.orange).foregroundColor(.white).cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                .padding()
            }
            .navigationTitle("Accuracy Tester")
        }
    }
}

import SwiftUI
import PhotosUI
import CoreLocation
import CoreML
import Photos
import ImageIO

// MARK: - Main Tab View
struct ContentView: View {
    var body: some View {
        // ▼▼▼ [수정] 탭 바 구성을 아래와 같이 변경합니다. ▼▼▼
        TabView {
            // 탭 1: 앨범 생성기
            AlbumCreatorView()
                .tabItem {
                    Label("For You", systemImage: "wand.and.stars")
                }
            
            // 탭 2: 이미지 검색
            ImageSearchView()
                .tabItem {
                    Label("Search", systemImage: "text.magnifyingglass")
                }

            // 탭 3: 새로 만든 Testing 뷰
            TestingView()
                .tabItem {
                    Label("Testing", systemImage: "wrench.and.screwdriver")
                }
        }
        // ▲▲▲ [수정] 여기까지 ▲▲▲
    }
}

// MARK: - Smart POI Analyst View (기존 ContentView의 본체)
struct SmartPOIAnalystView: View {
    // State Variables
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var statusMessage: String = "Please select a photo to analyze."
    @State private var selectedImageCoordinate: CLLocationCoordinate2D?
    @State private var rankedCandidates: [RankedPOICandidate] = []
    
    // Services and Engine
    private let mobileCLIPClassifier = ZSImageClassification(model: defaultModel.factory())
    private let placesService = GooglePlacesAPIService()
    private var rankingEngine: POIRankingEngine {
        POIRankingEngine(classifier: mobileCLIPClassifier)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                if let img = selectedImage {
                    Image(uiImage: img).resizable().scaledToFit().cornerRadius(12).shadow(radius: 5).padding(.horizontal)
                } else {
                    Spacer()
                    Image(systemName: "photo.on.rectangle.angled").font(.system(size: 80)).foregroundColor(.gray.opacity(0.3))
                    Spacer()
                }
                
                if isLoading {
                    ProgressView { Text(statusMessage).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center) }.padding()
                } else if !rankedCandidates.isEmpty {
                    VStack {
                        Text("Analysis Complete: Does one of these look right?")
                            .font(.headline).padding(.top)
                        List(rankedCandidates) { candidate in
                            HStack(spacing: 15) {
                                Image(systemName: icon(forCategories: candidate.place.types))
                                    .font(.title3).frame(width: 30).foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading) {
                                    Text(candidate.place.name).fontWeight(.bold)
                                    ProgressView(value: candidate.finalScore, total: 1.2)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                }
                                
                                Spacer()
                                
                                Text(String(format: "%.0f", candidate.distance))
                                    .font(.caption.monospacedDigit()).foregroundColor(.secondary)
                                + Text("m").font(.caption).foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain).cornerRadius(10)
                    }
                    .padding(.horizontal)
                } else {
                    Text(statusMessage).font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                }
                
                Spacer()
                
                VStack(spacing: 15) {
                    if selectedImage != nil {
                        Button("📍 Analyze Smart POI") { Task { await runAnalysis() } }
                            .disabled(isLoading).padding().frame(maxWidth: .infinity).background(isLoading ? Color.gray : Color.green).foregroundColor(.white).cornerRadius(10)
                    }
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text(selectedImage == nil ? "Select Photo from Library" : "Select Another Photo").padding().frame(maxWidth: .infinity).background(Color.blue).foregroundColor(.white).cornerRadius(10)
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .navigationTitle("Smart POI Analyzer")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { newItem in Task { await loadImage(from: newItem) } }
            .task { await mobileCLIPClassifier.load() }
        }
    }
    
    // Helper Functions
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        await MainActor.run {
            isLoading = true
            rankedCandidates = []
            selectedImageCoordinate = nil
            statusMessage = "Loading image and analyzing metadata..."
        }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let uiImage = UIImage(data: data)
                let coordinate = extractGPS(from: data)
                await MainActor.run {
                    self.selectedImage = uiImage
                    self.selectedImageCoordinate = coordinate
                    self.statusMessage = "Image loaded. Ready to analyze."
                }
            }
        } catch { await MainActor.run { statusMessage = "Failed to load image." } }
        await MainActor.run { isLoading = false }
    }
    
    private func extractGPS(from imageData: Data) -> CLLocationCoordinate2D? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let gpsDict = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else { return nil }
        guard let lat = gpsDict[kCGImagePropertyGPSLatitude] as? CLLocationDegrees,
              let lon = gpsDict[kCGImagePropertyGPSLongitude] as? CLLocationDegrees,
              let latRef = gpsDict[kCGImagePropertyGPSLatitudeRef] as? String,
              let lonRef = gpsDict[kCGImagePropertyGPSLongitudeRef] as? String else { return nil }
        let finalLat = (latRef == "N") ? lat : -lat
        let finalLon = (lonRef == "E") ? lon : -lon
        return CLLocationCoordinate2D(latitude: finalLat, longitude: finalLon)
    }
    
    private func icon(forCategories categories: [String]) -> String {
        let appCategories = CategoryMapper.map(googleTypes: categories)
        if let primaryCategory = appCategories.first {
            return primaryCategory.iconName
        }
        return "mappin.and.ellipse"
    }
    
    // Core Analysis Logic
    @MainActor
    private func runAnalysis() async {
        guard let image = selectedImage,
              let pixelBuffer = image.toCVPixelBuffer() else {
            statusMessage = "Error: Failed to process image."; return
        }
        
        isLoading = true
        rankedCandidates = []
        statusMessage = "1/2: Searching for nearby places..."
        
        guard let coordinate = selectedImageCoordinate else {
            statusMessage = "Error: GPS information not found in this photo."; isLoading = false; return
        }
        
        do {
            // --- ▼▼▼ 여기가 수정된 부분입니다 ▼▼▼ ---
            
            // 1. 올바른 함수 이름 'fetchAndCategorizePlaces'를 호출합니다.
            let categorizedPlaces = try await placesService.fetchAndCategorizePlaces(for: coordinate)
            
            if categorizedPlaces.isEmpty {
                statusMessage = "No nearby places were found."; isLoading = false; return
            }
            
            // 2. POIRankingEngine에 전달하기 위해 [Place] 데이터만 추출합니다.
            let placesToRank = categorizedPlaces.map { $0.place }
            
            // --- ▲▲▲ 수정 끝 ▲▲▲ ---
            
            statusMessage = "2/2: Running smart ranking algorithm..."
            
            // POIRankingEngine에는 순수한 [Place] 배열을 전달합니다.
            let finalRankedList = await rankingEngine.rankPlaces(
                places: placesToRank,
                imagePixelBuffer: pixelBuffer,
                photoLocation: coordinate
            )
            
            self.rankedCandidates = finalRankedList
            
            if self.rankedCandidates.isEmpty {
                statusMessage = "Analysis complete, but no matching places were found."
            }
            
        } catch {
            statusMessage = "Error: API request failed.\n\(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

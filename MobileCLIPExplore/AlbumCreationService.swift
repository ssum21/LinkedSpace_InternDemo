import Foundation
import CoreLocation
import Vision
import Photos
import UIKit
import CoreML

@MainActor
class AlbumCreationService {

    // MARK: - Dependencies & Properties
    
    private let rankingEngine: POIRankingEngine
    private let mobileCLIPClassifier: ZSImageClassification
    
    /// A closure to update the status message on the UI.
    var statusMessageUpdater: ((String) -> Void)?

    // MARK: - Clustering Parameters
    
    /// [Level 2] The maximum distance (in meters) for photos to be considered part of the same Moment.
    private let spatialThreshold: CLLocationDistance = 175.0
    
    /// [Level 2] The maximum time gap (in seconds) for photos to be considered part of the same Moment.
    private let temporalThreshold: TimeInterval = 3 * 60 * 60 // 3 hours
    
    /// [Level 3] The minimum similarity score for photos to be grouped into the same Highlight.
    /// This is stricter than the Moment clustering to group only visually very similar photos.
    private let highlightSimilarityThreshold: Float = 0.85

    // MARK: - Initialization
    
    init(rankingEngine: POIRankingEngine, classifier: ZSImageClassification) {
        self.rankingEngine = rankingEngine
        self.mobileCLIPClassifier = classifier
    }

    // MARK: - Main Execution Flow
    
    /// The primary function to create a complete TripAlbum from a set of photos.
    /// This orchestrates the entire 3-level clustering process.
    /// - Parameter photoAssets: An array of `PhotoAsset` objects, pre-sorted by creation date.
    /// - Returns: A fully structured `TripAlbum`.
    func createAlbum(from photoAssets: [PhotoAsset]) async throws -> TripAlbum {
        // Level 1 (Trip) is pre-determined by the input `photoAssets` array.
        
        // Level 2: Cluster photos into "Moments" based on time and location.
        statusMessageUpdater?("Step 1/3: Finding Moments...")
        let momentClusters = performMomentClustering(on: photoAssets)
        
        // For each Moment, identify its Point of Interest (POI) name using the ranking engine.
        statusMessageUpdater?("Step 2/3: Analyzing Places...")
        for (index, cluster) in momentClusters.enumerated() {
            statusMessageUpdater?("Analyzing Places... (\(index + 1)/\(momentClusters.count))")
            await identifyPOIName(for: cluster)
        }
        
        // Level 3: Structure the final album, creating "Highlights" within each Moment.
        statusMessageUpdater?("Step 3/3: Creating Highlights...")
        let album = generateAlbumStructure(from: momentClusters)
        
        return album
    }

    // MARK: - Level 2: Moment Clustering (Place/Event)
    
    /// Groups photos into `PhotoCluster` objects (representing Moments) based on spatio-temporal proximity.
    private func performMomentClustering(on sortedAssets: [PhotoAsset]) -> [PhotoCluster] {
        var clusters: [PhotoCluster] = []
        
        for asset in sortedAssets {
            if let bestCluster = findBestMomentCluster(for: asset, among: clusters) {
                bestCluster.add(asset: asset)
            } else {
                let newCluster = PhotoCluster(initialAsset: asset)
                clusters.append(newCluster)
            }
        }
        return clusters.filter { !$0.photoAssets.isEmpty }
    }
    
    /// Finds the most suitable existing cluster for a new photo.
    /// In this logic, it only checks against the most recent cluster for efficiency.
    private func findBestMomentCluster(for asset: PhotoAsset, among clusters: [PhotoCluster]) -> PhotoCluster? {
        guard let lastCluster = clusters.last else { return nil }

        let distance = asset.location.distance(from: lastCluster.representativeLocation)
        let timeDifference = asset.creationDate.timeIntervalSince(lastCluster.endTime)

        // A new cluster is formed if the photo is too far away or taken too long after the previous one.
        if distance < spatialThreshold && timeDifference < temporalThreshold {
            return lastCluster
        }
        
        return nil
    }
    
    /// Uses the ranking engine to determine the name of the place for a given Moment cluster.
    private func identifyPOIName(for cluster: PhotoCluster) async {
        guard let coverAsset = cluster.coverAsset,
              let image = await getHighQualityImage(for: coverAsset.asset),
              let pixelBuffer = image.toCVPixelBuffer() else {
            cluster.identifiedPOIName = "Unknown Place"
            return
        }

        let photoCoordinate = coverAsset.location.coordinate
        let placesService = GooglePlacesAPIService()

        do {
            let categorizedPlaces = try await placesService.fetchAndCategorizePlaces(for: photoCoordinate)
            if categorizedPlaces.isEmpty {
                cluster.identifiedPOIName = "No Nearby Places"
                return
            }
            
            let placesToRank = categorizedPlaces.map { $0.place }
            let rankedCandidates = await rankingEngine.rankPlaces(
                places: placesToRank,
                imagePixelBuffer: pixelBuffer,
                photoLocation: photoCoordinate
            )
            
            cluster.identifiedPOIName = rankedCandidates.first?.place.name ?? "Recommended Place"
            cluster.poiCandidates = Array(rankedCandidates.prefix(10))
            
        } catch {
            print("Error identifying POI name: \(error)")
            cluster.identifiedPOIName = "Place Search Failed"
        }
    }
    
    // MARK: - Level 3: Highlight Clustering (Similar Photos)

    /// 사진들을 시각적 유사도에 따라 '하이라이트'와 '추가 가능한 사진'으로 정확히 분류합니다.
    private func createHighlights(from assets: [PhotoAsset]) -> (highlights: [Highlight], optionals: [PhotoAsset]) {
        guard !assets.isEmpty else { return ([], []) }

        var tempClusters: [[PhotoAsset]] = []

        // 모든 사진을 순회하며 가장 적합한 클러스터를 찾거나 새로 만듬
        for asset in assets {
            guard let assetEmbedding = asset.imageEmbedding else { continue }
            
            var bestMatchIndex: Int? = nil
            var maxSimilarity: Float = 0.0

            // 가장 유사한 기존 클러스터를 찾습니다.
            for (index, cluster) in tempClusters.enumerated() {
                // 클러스터의 대표 임베딩(첫 번째 사진)과 비교합니다.
                guard let representativeAsset = cluster.first, let repEmbedding = representativeAsset.imageEmbedding else { continue }
                
                let similarity = mobileCLIPClassifier.cosineSimilarity(assetEmbedding, repEmbedding)
                
                // 임계값을 넘고, 지금까지 찾은 것 중 가장 유사도가 높으면 후보로 지정합니다.
                if similarity > highlightSimilarityThreshold && similarity > maxSimilarity {
                    maxSimilarity = similarity
                    bestMatchIndex = index
                }
            }

            // 2. 적합한 클러스터를 찾았으면 추가하고, 아니면 새 클러스터를 생성합니다.
            if let index = bestMatchIndex {
                tempClusters[index].append(asset)
            } else {
                // 어떤 클러스터와도 유사하지 않으면, 자신만으로 구성된 새 클러스터를 만듭니다.
                tempClusters.append([asset])
            }
        }
        
        // 3. 생성된 임시 클러스터들을 최종 '하이라이트'와 '추가 가능 사진'으로 분리합니다.
        var finalHighlights: [Highlight] = []
        var optionalAssets: [PhotoAsset] = []

        for cluster in tempClusters {
            guard let representative = cluster.first else { continue }
            
            if cluster.count > 1 {
                // 사진이 2장 이상 묶인 클러스터는 '하이라이트'로 인정합니다.
                let ids = cluster.map { $0.id }
                let highlight = Highlight(representativeAssetId: representative.id, assetIds: ids)
                finalHighlights.append(highlight)
            } else {
                // 사진이 1장 뿐인 클러스터는 "판단이 애매한" 경우이므로 '추가 가능한 사진'으로 분류합니다.
                optionalAssets.append(representative)
            }
        }
        
        // '추가 가능 사진'들을 시간순으로 정렬
        optionalAssets.sort { $0.creationDate < $1.creationDate }
        
        return (highlights: finalHighlights, optionals: optionalAssets)
    }

    // MARK: - Final Album Structuring

    private func generateAlbumStructure(from momentClusters: [PhotoCluster]) -> TripAlbum {
        // Group Moment clusters by date.
        let groupedByDate = Dictionary(grouping: momentClusters) { cluster -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: cluster.startTime)
        }

        var albumDays: [Day] = []
        let sortedDates = groupedByDate.keys.sorted()

        for dateString in sortedDates {
            guard let clustersForDay = groupedByDate[dateString], !clustersForDay.isEmpty else { continue }
            
            let moments: [Moment] = clustersForDay.compactMap { cluster in
                guard let name = cluster.identifiedPOIName, let repAsset = cluster.coverAsset else { return nil }
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let time = timeFormatter.string(from: cluster.startTime)
                
                let (highlights, optionalAssets) = createHighlights(from: cluster.photoAssets)
                
                guard !highlights.isEmpty || !optionalAssets.isEmpty else {
                    return nil
                }
                
                // --- 여기가 핵심 수정 사항입니다 ---
                // rankedCandidate에서 위도(lat), 경도(lng)를 가져와 POICandidate를 생성합니다.
                let poiCandidates = cluster.poiCandidates.map { rankedCandidate in
                    POICandidate(
                        id: rankedCandidate.place.placeId,
                        name: rankedCandidate.place.name,
                        score: rankedCandidate.finalScore,
                        latitude: rankedCandidate.place.location.lat,
                        longitude: rankedCandidate.place.location.lng
                    )
                }
                return Moment(
                    name: name,
                    time: time,
                    representativeAssetId: repAsset.id,
                    highlights: highlights,
                    optionalAssetIds: optionalAssets.map { $0.id },
                    poiCandidates: poiCandidates
                )
            }
            
            guard !moments.isEmpty else { continue }

            let coverImageIdentifier = moments.first?.representativeAssetId ?? ""
            let summary = moments.map { $0.name }.prefix(3).joined(separator: ", ") + " & more"
            
            let day = Day(date: dateString, coverImage: coverImageIdentifier, summary: summary, moments: moments)
            albumDays.append(day)
        }
        
        let albumTitle = generateAlbumTitle(from: sortedDates)
        return TripAlbum(albumTitle: albumTitle, days: albumDays)
    }

    // MARK: - Helper Functions
    
    private func generateAlbumTitle(from dates: [String]) -> String {
        guard let firstDateStr = dates.first, let lastDateStr = dates.last else { return "A Trip Album" }
        if firstDateStr == lastDateStr {
            return "Trip of \(firstDateStr)"
        }
        return "Trip: \(firstDateStr) - \(lastDateStr)"
    }
    
    private func getHighQualityImage(for asset: PHAsset) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 1024, height: 1024), contentMode: .aspectFit, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

import Foundation
import CoreLocation
import CoreML

struct RankedPOICandidate: Identifiable {
    let id = UUID()
    let place: Place
    var distance: CLLocationDistance
    var clipScore: Float = 0.0
    var finalScore: Float = 0.0
}

class POIRankingEngine {
    
    private let clipWeight: Float = 0.3
    private let distanceWeight: Float = 0.7
    private let genericTagsBlacklist: Set<String> = ["point_of_interest", "establishment", "store"]

    private let mobileCLIPClassifier: ZSImageClassification
    
    init(classifier: ZSImageClassification) {
        self.mobileCLIPClassifier = classifier
    }
    
    func rankPlaces(places: [Place], imagePixelBuffer: CVPixelBuffer, photoLocation: CLLocationCoordinate2D) async -> [RankedPOICandidate] {
        
        var candidates: [RankedPOICandidate] = places.map { place in
            let placeLocation = CLLocation(latitude: place.location.lat, longitude: place.location.lng)
            let photoCLLocation = CLLocation(latitude: photoLocation.latitude, longitude: photoLocation.longitude)
            let distance = photoCLLocation.distance(from: placeLocation)
            return RankedPOICandidate(place: place, distance: distance)
        }

        // 이미지 임베딩 생성 (단 1회)
        guard let imageEmbeddingResult = await mobileCLIPClassifier.computeImageEmbeddings(frame: imagePixelBuffer) else { return [] }
        let imageEmbedding = imageEmbeddingResult.embedding

        // 고품질 태그 추출 및 텍스트 임베딩 미리 계산
        var allHighQualityTags: Set<String> = []
        for candidate in candidates {
            let tags = extractHighQualityTags(from: candidate.place.types)
            for tag in tags { allHighQualityTags.insert(tag) }
        }
        let textEmbeddings = await mobileCLIPClassifier.computeTextEmbeddings(promptArr: Array(allHighQualityTags))
        let tagEmbeddingMap = Dictionary(uniqueKeysWithValues: zip(allHighQualityTags, textEmbeddings))

        // 각 후보별로 점수를 후처리 계산
        for i in 0..<candidates.count {
            let tags = extractHighQualityTags(from: candidates[i].place.types)
            var maxScore: Float = 0.0
            for tagName in tags {
                if let textEmbedding = tagEmbeddingMap[tagName] {
                    let similarity = mobileCLIPClassifier.cosineSimilarity(imageEmbedding, textEmbedding)
                    if similarity > maxScore { maxScore = similarity }
                }
            }
            candidates[i].clipScore = maxScore
        }

        // 최종 점수 계산 (휴리스틱 결합)
        for i in 0..<candidates.count {
            let candidate = candidates[i]
            let distanceScore = exp(-Float(candidate.distance) / 100.0)
            
            // ▼▼▼ 새롭게 개선된 getPriorityBonus 함수 호출 ▼▼▼
            let priorityBonus = getPriorityBonus(for: candidate.place.types)
            let proximityBonus = getProximityBonus(for: candidate.distance, types: candidate.place.types)
            
            let finalScore = (candidate.clipScore * clipWeight) + (distanceScore * distanceWeight) + priorityBonus + proximityBonus
            candidates[i].finalScore = finalScore
        }
        
        return candidates.sorted { $0.finalScore > $1.finalScore }
    }
    
    private func extractHighQualityTags(from types: [String]) -> [String] {
        return types.filter { !genericTagsBlacklist.contains($0) }.map { $0.replacingOccurrences(of: "_", with: " ") }
    }
    
    // MARK: - Heuristic Rule Functions
    
    /// **[새롭게 개선된 함수]** POI 유형의 중요도에 따라 보너스 점수를 5단계로 세분화하여 반환합니다.
    private func getPriorityBonus(for types: [String]) -> Float {
        let placeTypes = Set(types)
        
        // Level 1: 최고 우선순위 (주요 랜드마크 및 교통/교육 허브)
        // 사진의 주된 목적지일 확률이 가장 높은 장소들.
        let level1: Set<String> = [
            "airport", "university", "stadium", "amusement_park", "national_park",
            "train_station", "subway_station", "transit_station"
        ]
        if !placeTypes.isDisjoint(with: level1) { return 0.12 }
        
        // Level 2: 매우 높은 우선순위 (주요 관광지 및 대형 상업/문화 시설)
        // 여행의 핵심 목적지가 될 수 있는 중요한 장소들.
        let level2: Set<String> = [
            "tourist_attraction", "historical_landmark", "resort", "golf_course",
            "shopping_mall", "museum", "art_gallery", "zoo", "aquarium"
        ]
        if !placeTypes.isDisjoint(with: level2) { return 0.09 }
        
        // Level 3: 높은 우선순위 (일상적인 주요 방문지)
        // 식사, 만남, 휴식 등 일반적인 활동의 중심이 되는 장소들.
        let level3: Set<String> = [
            "restaurant", "park", "hotel", "market", "cafe", "bar"
        ]
        if !placeTypes.isDisjoint(with: level3) { return 0.06 }
        
        // Level 4: 보통 우선순위 (특정 목적의 소매점 및 서비스)
        // 구체적인 필요에 의해 방문하는 장소들.
        let level4: Set<String> = [
            "bakery", "ice_cream_shop", "department_store", "clothing_store", "book_store",
            "car_rental", "movie_theater", "spa"
        ]
        if !placeTypes.isDisjoint(with: level4) { return 0.03 }
        
        // 그 외 모든 장소는 보너스 없음
        return 0.0
    }
    
    private func getProximityBonus(for distance: CLLocationDistance, types: [String]) -> Float {
        if types.contains("hotel") || types.contains("resort") {
            if distance < 80 { return 0.25 }
        }
        if distance < 40 { return 0.20 }
        return 0.0
    }
}

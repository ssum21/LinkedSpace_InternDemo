import Foundation
import CoreLocation

// --- 최종 앨범 구조 ---
struct TripAlbum: Codable, Identifiable {
    let id: UUID
    var albumTitle: String
    var days: [Day]
    
    init(albumTitle: String = "새로운 여행", days: [Day] = []) {
        self.id = UUID()
        self.albumTitle = albumTitle
        self.days = days
    }
}

// --- 하루 단위 ---
struct Day: Codable, Identifiable {
    let id: UUID
    let date: String
    var coverImage: String
    var summary: String
    var moments: [Moment]
    
    init(date: String, coverImage: String, summary: String, moments: [Moment]) {
        self.id = UUID()
        self.date = date
        self.coverImage = coverImage
        self.summary = summary
        self.moments = moments
    }
}

struct POICandidate: Codable, Identifiable, Hashable {
    let id: String // Google Place ID
    let name: String
    let score: Float
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

}

// --- 장소/이벤트 단위 (Level 2) ---
struct Moment: Codable, Identifiable {
    let id: UUID
    var name: String
    let time: String
    var representativeAssetId: String // 대표 사진이 바뀔 수 있으므로 var로 변경
    var highlights: [Highlight]
    var optionalAssetIds: [String]
    let poiCandidates: [POICandidate]
    var voiceMemoPath: String? // 녹음 파일의 경로를 저장
    var caption: String?       // 사용자가 작성한 텍스트 캡션


    var allAssetIds: [String] {
        highlights.flatMap { $0.assetIds } + optionalAssetIds
    }

    // ▼▼▼ [수정] Codable 준수를 위해 모든 저장 프로퍼티를 포함하는 init을 명시합니다. ▼▼▼
    init(id: UUID = UUID(), name: String, time: String, representativeAssetId: String, highlights: [Highlight], optionalAssetIds: [String], poiCandidates: [POICandidate],  voiceMemoPath: String? = nil, caption: String? = nil) {
        self.id = id
        self.name = name
        self.time = time
        self.representativeAssetId = representativeAssetId
        self.highlights = highlights
        self.optionalAssetIds = optionalAssetIds
        self.poiCandidates = poiCandidates
        self.voiceMemoPath = voiceMemoPath
        self.caption = caption
    }
    // ▲▲▲ [수정] 여기까지 ▲▲▲
}

// --- 유사 사진 단위 (Level 3) ---
struct Highlight: Codable, Identifiable {
    let id: UUID
    var representativeAssetId: String // 대표 사진이 바뀔 수 있으므로 var로 변경
    var assetIds: [String]
    
    init(id: UUID = UUID(), representativeAssetId: String, assetIds: [String]) {
        self.id = id
        self.representativeAssetId = representativeAssetId
        self.assetIds = assetIds
    }
}

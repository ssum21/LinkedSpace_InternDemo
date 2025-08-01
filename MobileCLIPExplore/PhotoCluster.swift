import Foundation
import CoreLocation

// 사진 그룹(클러스터)을 표현하는 클래스
class PhotoCluster: Identifiable {
    let id = UUID()
    var photoAssets: [PhotoAsset]
    
    // 클러스터의 대표 속성들
    var representativeLocation: CLLocation
    var startTime: Date
    var endTime: Date
    
    // 클러스터에 대한 분석 결과
    var identifiedPOIName: String?
    
    // ▼▼▼ [추가] poiCandidates 프로퍼티를 여기에 추가합니다. ▼▼▼
    var poiCandidates: [RankedPOICandidate] = []
    // ▲▲▲ [추가] 여기까지 ▲▲▲
    
    var coverAsset: PhotoAsset? {
        return photoAssets.sorted(by: { $0.creationDate < $1.creationDate }).first
    }

    init(initialAsset: PhotoAsset) {
        self.photoAssets = [initialAsset]
        self.representativeLocation = initialAsset.location
        self.startTime = initialAsset.creationDate
        self.endTime = initialAsset.creationDate
    }

    // 새 사진을 클러스터에 추가하고 대표 속성들을 업데이트하는 메서드
    func add(asset: PhotoAsset) {
        photoAssets.append(asset)
        if asset.creationDate > endTime {
            endTime = asset.creationDate
        }
    }
}

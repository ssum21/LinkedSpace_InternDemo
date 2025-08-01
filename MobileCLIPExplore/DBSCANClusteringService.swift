//
//  DBSCANClusteringService.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/24/25.
//

import Foundation
import CoreLocation
import CoreML

class DBSCANClusteringService {
    
    // MARK: - Parameters
    
    /// DBSCAN: 클러스터로 인정될 최소 사진 개수
    let minPts: Int
    
    /// DBSCAN: 두 점이 이웃으로 간주될 최대 거리 (가중치 적용 후 0~1 사이 값)
    let eps: Double
    
    /// 거리 계산 시 시각적 유사도에 적용할 가중치
    let visualWeight: Double
    
    /// 거리 계산 시 지리적 거리에 적용할 가중치
    let geoWeight: Double
    
    /// 지리적 거리를 정규화할 때 사용할 최대 거리 (단위는 meter)
    /// 이 거리보다 멀면 지리적 거리는 1.0으로 간주
    let maxGeoDistance: Double

    private let mobileCLIPClassifier: ZSImageClassification

    init(classifier: ZSImageClassification,
         minPts: Int = 3,
         eps: Double = 0.3,
         visualWeight: Double = 0.7,
         geoWeight: Double = 0.3,
         maxGeoDistance: Double = 200.0) {
        self.mobileCLIPClassifier = classifier
        self.minPts = minPts
        self.eps = eps
        self.visualWeight = visualWeight
        self.geoWeight = geoWeight
        self.maxGeoDistance = maxGeoDistance
    }
    
    /// DBSCAN 알고리즘을 실행하여 사진들을 클러스터로 그룹화합니다.
    /// - Parameter photos: 클러스터링할 `PhotoAsset` 배열
    /// - Returns: 클러스터링된 결과. 각 배열은 하나의 클러스터를 나타냅니다. (Noise 포인트는 제외됨)
    func performClustering(on photos: [PhotoAsset]) -> [[PhotoAsset]] {
        guard photos.count >= minPts else { return [] }
        
        let dbscan = DBSCAN(aDB: photos)
        
        // DBSCAN 실행 (핵심: 사용자 정의 거리 함수 전달)
        dbscan.DBSCAN(distFunc: customDistance, eps: eps, minPts: minPts)
        
        // 결과 처리: 레이블별로 그룹화
        let labeledPhotos = dbscan.label
        
        // "Noise"로 분류된 사진들을 제외하고 클러스터 ID별로 묶습니다.
        let clusters = Dictionary(grouping: photos.filter { labeledPhotos[$0] != "Noise" }) {
            labeledPhotos[$0]!
        }
        
        // 딕셔너리의 값들(클러스터 배열)만 반환합니다.
        return Array(clusters.values)
    }

    /// **[핵심]** 두 PhotoAsset 간의 최종 거리를 계산하는 사용자 정의 함수
    /// 시각적 거리와 지리적 거리를 정규화하고 가중치를 적용하여 결합합니다.
    private func customDistance(p1: PhotoAsset, p2: PhotoAsset) -> Double {
        // 1. 시각적 거리 계산 (Cosine Distance)
        let visualDistance = calculateVisualDistance(p1, p2)
        
        // 2. 지리적 거리 계산 (Geographic Distance)
        let geoDistance = p1.location.distance(from: p2.location)
        
        // 3. 각 거리를 0~1 사이로 정규화(Normalize)
        // 코사인 거리는 0~2 범위이므로 2로 나누어 정규화합니다.
        let normalizedVisual = visualDistance / 2.0
        
        // 지리적 거리는 maxGeoDistance를 기준으로 정규화합니다. (최대값 1.0)
        let normalizedGeo = min(1.0, geoDistance / maxGeoDistance)
        
        // 4. 가중치를 적용하여 최종 거리 계산
        let finalDistance = (normalizedVisual * visualWeight) + (normalizedGeo * geoWeight)
        
        return finalDistance
    }
    
    private func calculateVisualDistance(_ p1: PhotoAsset, _ p2: PhotoAsset) -> Double {
        guard let embedding1 = p1.imageEmbedding, let embedding2 = p2.imageEmbedding else {
            // 임베딩이 없는 경우, 최대 거리(2.0)를 반환하여 다른 클러스터에 속하게 함
            return 2.0
        }
        // 코사인 유사도는 -1~1, 코사인 거리는 0~2 입니다.
        let similarity = mobileCLIPClassifier.cosineSimilarity(embedding1, embedding2)
        return 1.0 - Double(similarity)
    }
}

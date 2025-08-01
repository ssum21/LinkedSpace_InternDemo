//
//  PhotoAsset.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/17/25.
//

import Foundation
import Photos
import CoreLocation
import CoreML

// 클러스터링에 사용될 사진 데이터 모델
struct PhotoAsset: Identifiable, Hashable {
    let id: String // PHAsset.localIdentifier
    let asset: PHAsset
    let location: CLLocation
    let creationDate: Date
    let imageEmbedding: MLMultiArray? // CLIP 이미지 임베딩 벡터
    
    // MLMultiArray는 Hashable이 아니므로, 고유 ID를 기반으로 해시하고 비교합니다.
    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

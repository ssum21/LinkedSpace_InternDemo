//
//  TripDetectorService.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/17/25.
//

import Foundation

class TripDetectorService {
    
    // 두 사진 사이의 시간 간격이 이 이상 벌어지면 다른 여행으로 간주합니다. (예: 48시간)
    private let tripSeparationThreshold: TimeInterval = 48 * 60 * 60

    /// 시간순으로 정렬된 사진 에셋들을 받아서 여러 개의 여행으로 분리합니다.
    /// - Parameter sortedAssets: 시간순(오름차순)으로 정렬된 PhotoAsset 배열
    /// - Returns: 각 여행에 해당하는 PhotoAsset 배열의 배열 (e.g., [[하와이 여행 사진들], [제주도 여행 사진들]])
    func detectTrips(from sortedAssets: [PhotoAsset]) -> [[PhotoAsset]] {
        guard !sortedAssets.isEmpty else { return [] }

        var allTrips: [[PhotoAsset]] = []
        var currentTrip: [PhotoAsset] = []

        for asset in sortedAssets {
            // 현재 여행에 사진이 이미 있다면, 마지막 사진과 시간 비교
            if let lastAssetInTrip = currentTrip.last {
                let timeDifference = asset.creationDate.timeIntervalSince(lastAssetInTrip.creationDate)
                
                // 시간 차이가 임계값보다 크면, 현재 여행을 마감하고 새 여행 시작
                if timeDifference > tripSeparationThreshold {
                    allTrips.append(currentTrip) // 완성된 여행 추가
                    currentTrip = [asset]       // 새 여행 시작
                } else {
                    currentTrip.append(asset)   // 시간 차이가 작으면 현재 여행에 계속 추가
                }
            } else {
                // 첫 사진은 무조건 새 여행의 시작
                currentTrip.append(asset)
            }
        }

        // 마지막으로 진행 중이던 여행 추가
        if !currentTrip.isEmpty {
            allTrips.append(currentTrip)
        }

        return allTrips
    }
}

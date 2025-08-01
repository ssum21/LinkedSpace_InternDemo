//
//  StatisticalOutlierDetector.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/24/25.
//

import Foundation
import CoreML
import Accelerate

class StatisticalOutlierDetector {
    
    /// 이상치로 판단하는 기준값. 이 값보다 MAD 점수가 높으면 이상치로 간주됩니다. (2.0 ~ 3.0 사이가 일반적)
    private let madThreshold: Double
    
    init(threshold: Double = 2.5) {
        self.madThreshold = threshold
    }
    
    /// 클러스터 내에서 시각적 이상치를 찾아 제거합니다.
    /// - Parameter cluster: `PhotoAsset`으로 구성된 단일 클러스터
    /// - Returns: 이상치가 제거된 `PhotoAsset` 배열
    func removeOutliers(from cluster: [PhotoAsset]) -> [PhotoAsset] {
        guard cluster.count > 2 else { return cluster }
        
        let embeddings = cluster.compactMap { $0.imageEmbedding }
        guard !embeddings.isEmpty else { return cluster }
        
        // 1. 클러스터의 '시각적 중심' (Median Embedding)을 계산합니다.
        guard let medianEmbedding = calculateMedianEmbedding(for: embeddings) else { return cluster }
        
        // 2. 각 사진과 시각적 중심 사이의 코사인 거리를 계산합니다.
        let distances = embeddings.map { 1.0 - cosineSimilarity(medianEmbedding, $0) }
        
        // 3. Median Absolute Deviation (MAD)를 계산합니다.
        guard let medianOfDistances = median(distances) else { return cluster }
        
        let absoluteDeviations = distances.map { abs($0 - medianOfDistances) }
        guard let mad = median(absoluteDeviations) else { return cluster }
        
        // MAD가 0이면 모든 데이터가 동일하다는 의미이므로 이상치가 없습니다.
        if mad == 0 {
            return cluster
        }
        
        var filteredCluster: [PhotoAsset] = []
        for (index, photo) in cluster.enumerated() {
            // 4. 각 사진의 MAD 점수(Robust Z-score)를 계산합니다.
            let distance = distances[index]
            let madScore = abs(distance - medianOfDistances) / mad
            
            // 5. MAD 점수가 임계값보다 낮은 사진만 유지합니다.
            if madScore < madThreshold {
                filteredCluster.append(photo)
            } else {
                print("Outlier detected and removed: Asset ID \(photo.id)")
            }
        }
        
        return filteredCluster
    }
    
    // MARK: - Helper Functions
    
    private func calculateMedianEmbedding(for embeddings: [MLMultiArray]) -> MLMultiArray? {
        guard let firstEmbedding = embeddings.first else { return nil }
        let embeddingLength = firstEmbedding.count
        var medianValues = [Double](repeating: 0.0, count: embeddingLength)
        
        for i in 0..<embeddingLength {
            let dimensionValues = embeddings.map { Double($0[i].floatValue) }
            if let medianValue = median(dimensionValues) {
                medianValues[i] = medianValue
            }
        }
        
        let floatMedianValues = medianValues.map { Float($0) }
        return try? MLMultiArray(shape: firstEmbedding.shape, dataType: .float32, initialValue: floatMedianValues)
    }
    
    private func median(_ array: [Double]) -> Double? {
        guard !array.isEmpty else { return nil }
        let sorted = array.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        } else {
            return sorted[mid]
        }
    }
    
    private func cosineSimilarity(_ a: MLMultiArray, _ b: MLMultiArray) -> Double {
        guard a.count == b.count,
              let pointerA = try? UnsafeBufferPointer<Float>(a),
              let pointerB = try? UnsafeBufferPointer<Float>(b),
              let baseAddressA = pointerA.baseAddress,   // .baseAddress를 사용하여 UnsafePointer 추출
              let baseAddressB = pointerB.baseAddress else { // .baseAddress를 사용하여 UnsafePointer 추출
            return 0.0
        }
        
        var similarity: Float = 0
        // baseAddressA, baseAddressB를 전달
        vDSP_dotpr(baseAddressA, 1, baseAddressB, 1, &similarity, vDSP_Length(a.count))
        
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0
        // baseAddressA를 전달
        vDSP_rmsqv(baseAddressA, 1, &magnitudeA, vDSP_Length(a.count))
        // baseAddressB를 전달
        vDSP_rmsqv(baseAddressB, 1, &magnitudeB, vDSP_Length(b.count))
        
        let magnitude = magnitudeA * magnitudeB * Float(a.count)
        
        return magnitude == 0 ? 0.0 : Double(similarity / magnitude)
    }
}
// MLMultiArray 초기화를 위한 편의 확장
extension MLMultiArray {
    convenience init(shape: [NSNumber], dataType: MLMultiArrayDataType, initialValue: [Float]) throws {
        try self.init(shape: shape, dataType: dataType)
        let buffer = try! UnsafeMutableBufferPointer<Float>(self)
        _ = buffer.initialize(from: initialValue)
    }
}

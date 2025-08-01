import Vision
import UIKit
import CoreML

// Vision 프레임워크를 사용한 이미지 분류 결과를 담을 구조체
struct VisionClassificationResult {
    let identifier: String
    let confidence: Float
}

@MainActor
class VisionClassifier: ObservableObject {
    // 1단계에서 추가한 Core ML 모델로 초기화합니다.
    // 모델 파일 이름이 'MobileNetV2.mlmodel'인 경우, Xcode는 'MobileNetV2' 클래스를 자동 생성합니다.
    private lazy var visionModel: VNCoreMLModel? = {
        do {
            let config = MLModelConfiguration()
            // 1단계에서 프로젝트에 추가한 모델의 클래스 이름으로 변경하세요.
            return try VNCoreMLModel(for: MobileNetV2(configuration: config).model)
        } catch {
            print("Vision Core ML 모델 로딩 실패: \(error)")
            return nil
        }
    }()

    /// 이미지를 분류하고 결과와 지연 시간을 반환합니다.
    /// - Parameter image: 분석할 UIImage
    /// - Returns: 분류 결과 배열과 처리 시간(초)을 담은 튜플
    func classifyImage(_ image: UIImage) async -> (results: [VisionClassificationResult], latency: TimeInterval)? {
        guard let model = visionModel else {
            print("Vision 모델이 준비되지 않았습니다.")
            return nil
        }
        
        guard let cgImage = image.cgImage else {
            print("CGImage로 변환할 수 없습니다.")
            return nil
        }

        let startTime = CACurrentMediaTime()

        // Vision 요청 생성
        let request = VNCoreMLRequest(model: model) { request, error in
            // 결과 처리는 아래에서 비동기적으로 수행
        }
        request.imageCropAndScaleOption = .centerCrop

        // 요청 핸들러 생성 및 실행
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        return await withCheckedContinuation { continuation in
            do {
                try handler.perform([request])
                
                let endTime = CACurrentMediaTime()
                let latency = endTime - startTime
                
                // 결과 처리
                if let observations = request.results as? [VNClassificationObservation] {
                    let classificationResults = observations.prefix(5).map {
                        VisionClassificationResult(identifier: $0.identifier, confidence: $0.confidence)
                    }
                    continuation.resume(returning: (results: classificationResults, latency: latency))
                } else {
                    continuation.resume(returning: (results: [], latency: latency))
                }
            } catch {
                print("Vision 요청 실패: \(error)")
                let endTime = CACurrentMediaTime()
                continuation.resume(returning: (results: [], latency: endTime - startTime))
            }
        }
    }
}

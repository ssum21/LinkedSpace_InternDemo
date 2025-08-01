//
// For licensing see accompanying LICENSE file.
// Copyright (C) 2024 Apple Inc. All Rights Reserved.
//

import CoreML
import UIKit

/// shared tokenizer for all model types
private let tokenizer = AsyncFactory {
    CLIPTokenizer()
}

actor ZSImageClassification: ObservableObject {

    private let ciContext = CIContext()
    private var model: any CLIPEncoder

    public init(model: any CLIPEncoder) {
        self.model = model
    }

    func load() async {
        async let t = tokenizer.get()
        async let m: () = model.load()
        _ = await (t, m)
    }

    public func setModel(_ model: ModelConfiguration) {
        self.model = model.factory()
    }

    // Compute Text Embeddings
    func computeTextEmbeddings(promptArr: [String]) async -> [MLMultiArray] {
        var textEmbeddings: [MLMultiArray] = []
        do {
            for singlePrompt in promptArr {
                let inputIds = await tokenizer.get().encode_full(text: singlePrompt)
                let inputArray = try MLMultiArray(shape: [1, 77], dataType: .int32)
                for (index, element) in inputIds.enumerated() {
                    inputArray[index] = NSNumber(value: element)
                }
                let output = try await model.encode(text: inputArray)
                textEmbeddings.append(output)
            }
        } catch {
            print(error.localizedDescription)
        }
        return textEmbeddings
    }

    // Compute Image Embeddings
    func computeImageEmbeddings(frame: CVPixelBuffer) async -> (
        embedding: MLMultiArray, interval: CFTimeInterval
    )? {
        var image: CIImage? = CIImage(cvPixelBuffer: frame)
        image = image?.cropToSquare()
        image = image?.resize(size: model.targetImageSize)

        guard let image else { return nil }

        let extent = image.extent
        let pixelFormat = kCVPixelFormatType_32ARGB
        var output: CVPixelBuffer?
        CVPixelBufferCreate(nil, Int(extent.width), Int(extent.height), pixelFormat, nil, &output)

        guard let output else {
            print("failed to create output CVPixelBuffer")
            return nil
        }

        ciContext.render(image, to: output)

        do {
            let startTimer = CACurrentMediaTime()
            let output = try await model.encode(image: output)
            let endTimer = CACurrentMediaTime()
            let interval = endTimer - startTimer
            return (embedding: output, interval: interval)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    // Compute cosine similarity between embeddings
    nonisolated func cosineSimilarity(_ embedding1: MLMultiArray, _ embedding2: MLMultiArray) -> Float {
        let e1 = embedding1.withUnsafeBufferPointer(ofType: Float.self) { Array($0) }
        let e2 = embedding2.withUnsafeBufferPointer(ofType: Float.self) { Array($0) }
        let dotProduct: Float = zip(e1, e2).reduce(0.0) { $0 + $1.0 * $1.1 }
        let magnitude1: Float = sqrt(e1.reduce(0) { $0 + pow($1, 2) })
        let magnitude2: Float = sqrt(e2.reduce(0) { $0 + pow($1, 2) })
        let similarity = dotProduct / (magnitude1 * magnitude2)
        return similarity
    }
    
    // ▼▼▼ 에러가 수정된 함수 ▼▼▼
    public func findBestContext(for frame: CVPixelBuffer, from contexts: [String]) async -> (context: String, score: Float)? {
        guard let imageEmbeddingResult = await computeImageEmbeddings(frame: frame) else {
            return nil
        }
        let imageEmbedding = imageEmbeddingResult.embedding
        
        var bestMatch: (context: String, score: Float)? = nil

        for context in contexts {
            let prompt = "A photo of a scene in a \(context)"
            
            // ------------------ 여기가 수정된 부분입니다 ------------------
            // 1. inputIds는 항상 값을 반환하므로 일반 상수로 선언합니다.
            let inputIds = await tokenizer.get().encode_full(text: prompt)
            
            // 2. inputArray 생성은 실패할 수 있으므로(try?) 옵셔널입니다. 여기에 guard let을 사용합니다.
            guard let inputArray = try? MLMultiArray(shape: [1, 77], dataType: .int32) else {
                continue // 실패하면 다음 컨텍스트로 넘어갑니다.
            }
            // ---------------------------------------------------------
            
            for (index, element) in inputIds.enumerated() {
                inputArray[index] = NSNumber(value: element)
            }

            do {
                let textEmbedding = try await model.encode(text: inputArray)
                let similarity = cosineSimilarity(imageEmbedding, textEmbedding)
                
                print("Testing context '\(context)' -> Score: \(similarity)")
                
                if bestMatch == nil || similarity > bestMatch!.score {
                    bestMatch = (context: context, score: similarity)
                }
            } catch {
                print("Error encoding text for context '\(context)': \(error)")
                continue
            }
        }
        
        return bestMatch
    }
}

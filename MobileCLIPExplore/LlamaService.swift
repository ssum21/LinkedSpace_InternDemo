// InferenceService.swift

import Foundation
import MediaPipeTasksGenAI

@MainActor
class InferenceService {
    /// MediaPipe의 LLM 추론 엔진 인스턴스
    private var llmInference: LlmInference?
    
    private(set) var modelStatusMessage = "Initializing AI Agent..."
    
    var isModelReady: Bool {
        return llmInference != nil
    }
    
    init() {
        let modelFileName = "Gemma2b"
        let modelExtension = "bin"
        
        guard let modelPath = Bundle.main.path(forResource: modelFileName, ofType: modelExtension) else {
            modelStatusMessage = "Model file '\(modelFileName).\(modelExtension)' not found."
            print("❌ \(modelStatusMessage)")
            return
        }
        
        // ▼▼▼ [핵심] 실제 Swift API에 맞는 올바른 초기화 방법 ▼▼▼
        do {
            // 1. LlmInference.Options를 modelPath를 사용하여 직접 초기화합니다.
            let llmOptions = LlmInference.Options(modelPath: modelPath)
            llmOptions.maxTokens = 2048 // 전체 컨텍스트 길이 설정
            
            // 2. 설정된 옵션으로 LlmInference를 초기화합니다.
            self.llmInference = try LlmInference(options: llmOptions)
            modelStatusMessage = "AI model is ready."
            print("✅ InferenceService: MediaPipe model loaded successfully.")
        } catch {
            modelStatusMessage = "Failed to load MediaPipe model: \(error.localizedDescription)"
            print("❌ InferenceService: \(modelStatusMessage)")
        }
    }
    
    /// 새로운 채팅 세션을 생성하여 반환합니다.
    func startChat() throws -> LlmInference.Session {
        guard let llmInference = llmInference else {
            throw NSError(domain: "InferenceServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model is not initialized."])
        }
        
        // 1. LlmInference.Session.Options를 생성합니다.
        let sessionOptions = LlmInference.Session.Options()
        sessionOptions.topk = 40
        sessionOptions.temperature = 0.7
        sessionOptions.randomSeed = 101
        
        // 2. LlmInference 인스턴스와 세션 옵션을 사용하여 새 세션을 생성합니다.
        return try LlmInference.Session(llmInference: llmInference, options: sessionOptions)
    }
}

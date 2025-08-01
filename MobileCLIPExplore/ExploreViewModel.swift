// ExploreViewModel.swift

import SwiftUI
import Combine
import MediaPipeTasksGenAI

// MARK: - Chat Message Model

/// 채팅 메시지 하나를 표현하는 데이터 모델.
/// ObservableObject를 채택하여 스트리밍으로 내용이 업데이트될 때 뷰가 실시간으로 변경되도록 합니다.
@MainActor
class ChatMessage: Identifiable, ObservableObject {
    let id = UUID()
    let isFromUser: Bool
    
    @Published var text: String
    @Published var isLoading: Bool
    
    init(text: String, isFromUser: Bool, isLoading: Bool = false) {
        self.text = text
        self.isFromUser = isFromUser
        self.isLoading = isLoading
    }
}


// MARK: - Explore View Model

@MainActor
class ExploreViewModel: ObservableObject {
    
    // MARK: - Published Properties for UI
    
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    /// 음성 녹음 중인지 여부를 UI에 바인딩하기 위한 프로퍼티
    @Published var isListening = false
    
    /// 실시간 음성 인식 텍스트를 UI에 표시하기 위한 프로퍼티
    @Published var transcribedText = ""
    
    // MARK: - Dependencies & Session
    
    private let llamaService = InferenceService()
    private let photoService = PhotoProcessingService.shared
    private var chatSession: LlmInference.Session?
    
    /// 음성 녹음 및 STT 기능을 처리하기 위해 기존 ViewModel을 재활용
    private let voiceMemoViewModel = VoiceMemoViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    
    init() {
        // 서비스의 초기 상태 메시지를 첫 메시지로 표시
        messages.append(ChatMessage(text: llamaService.modelStatusMessage, isFromUser: false))
        
        // 모델이 성공적으로 로드되었다면, 채팅 세션을 시작하고 환영 메시지를 추가
        if llamaService.isModelReady {
            startNewChat()
            messages.append(ChatMessage(text: "How can I help you find a memory?", isFromUser: false))
        }
        
        // VoiceMemoViewModel의 상태 변화를 이 ViewModel의 @Published 프로퍼티와 연결
        setupVoiceBindings()
    }
    
    // MARK: - Public Methods for View
    
    /// 에러 메시지를 초기화하여 UI의 Alert을 닫습니다.
    func clearError() {
        errorMessage = nil
    }
    
    /// 텍스트 또는 음성으로 인식된 사용자 쿼리를 처리하는 메인 로직
    func processUserQuery(text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty, !isGenerating else { return }
        
        guard let chatSession = chatSession else {
            errorMessage = "Chat session is not ready. Please restart the app."
            return
        }
        
        isGenerating = true
        
        // 1. 사진 데이터로부터 컨텍스트 생성
        let context = createContextFromPhotos()
        
        // 2. Llama3 Instruct 모델 형식에 맞는 최종 프롬프트 구성
        let fullPrompt = """
        <start_of_turn>system
        \(context)<end_of_turn>
        <start_of_turn>user
        \(text)<end_of_turn>
        <start_of_turn>model
        """
        
        // 3. UI에 사용자 메시지와 "생성 중" 상태의 AI 메시지 추가
        messages.append(ChatMessage(text: text, isFromUser: true))
        let assistantMessage = ChatMessage(text: "", isFromUser: false, isLoading: true)
        messages.append(assistantMessage)
        
        // 4. MediaPipe 세션을 통해 스트리밍 응답 생성
        do {
            try chatSession.addQueryChunk(inputText: fullPrompt)
            let stream = chatSession.generateResponseAsync()
            
            for try await partialResponse in stream {
                // 스트림에서 첫 번째 응답 조각을 받으면 로딩 상태를 false로 변경
                if assistantMessage.isLoading {
                    assistantMessage.isLoading = false
                }
                // 받은 조각을 메시지 텍스트에 계속 추가
                assistantMessage.text += partialResponse
            }
        } catch {
            // 에러 발생 시 로딩 상태를 해제하고 에러 메시지를 표시
            assistantMessage.isLoading = false
            assistantMessage.text = "Sorry, an error occurred: \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    /// 음성 입력을 시작하거나 중지합니다.
    func toggleVoiceListening() {
        if isListening {
            // --- 녹음 중지 ---
            voiceMemoViewModel.stopRecording()
            
            let finalText = transcribedText
            // 인식된 텍스트가 있다면, AI에게 질문으로 보냅니다.
            if !finalText.isEmpty {
                Task {
                    await processUserQuery(text: finalText)
                }
            }
            // 다음 입력을 위해 임시 텍스트를 초기화합니다.
            transcribedText = ""
        } else {
            // --- 녹음 시작 ---
            voiceMemoViewModel.startRecording(for: UUID())
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// 새로운 채팅 세션을 시작하거나, 기존 세션을 초기화합니다.
    func startNewChat() {
        do {
            self.chatSession = try llamaService.startChat()
        } catch {
            errorMessage = "Failed to start a new chat session: \(error.localizedDescription)"
        }
    }
    
    /// VoiceMemoViewModel의 @Published 프로퍼티들을 구독하여 상태를 동기화합니다.
    func setupVoiceBindings() {
        voiceMemoViewModel.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isListening)
            
        voiceMemoViewModel.$transcribedText
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcribedText)
    }
    
    /// 사진 데이터로부터 LLM에 제공할 컨텍스트 문자열을 생성합니다.
    private func createContextFromPhotos() -> String {
        guard !photoService.allPhotos.isEmpty else {
            return "No photo data is available to analyze."
        }
        
        var contextLines: [String] = [
            "You are a helpful AI assistant. Your task is to answer the user's question based ONLY on the context provided below.",
            "The context contains a summary of the user's recent photo memories.",
            "Do not use any external knowledge."
        ]
        
        let recentPhotos = photoService.allPhotos.suffix(30)
        
        for asset in recentPhotos {
            let dateString = asset.creationDate.formatted(date: .abbreviated, time: .shortened)
            let poiName = "a place near location (\(String(format: "%.4f", asset.location.coordinate.latitude)), \(String(format: "%.4f", asset.location.coordinate.longitude)))"
            contextLines.append("- A photo was taken at \(poiName) on \(dateString).")
        }
        
        return contextLines.joined(separator: "\n")
    }
}

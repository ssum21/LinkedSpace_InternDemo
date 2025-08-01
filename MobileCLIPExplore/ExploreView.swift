// ExploreView.swift

import SwiftUI

struct ExploreView: View {
    // @StateObject는 이 뷰가 소유하는 ViewModel을 생성하고 관리합니다.
    @StateObject private var viewModel = ExploreViewModel()
    
    // Alert을 표시하기 위한 State 변수
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Conversation History
                conversationHistoryView
                
                // MARK: - Prompt Input Area
                promptArea
            }
            .navigationTitle("LS Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 대화 내용 초기화 버튼 (선택사항)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.messages.removeAll()
                    }) {
                        Image(systemName: "arrow.counter.clockwise")
                    }
                }
                
                // 생성 중지 버튼
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isGenerating {
                        Button("Stop", action: {
                            // TODO: 생성 중지 로직 (Task cancellation)
                        })
                    }
                }
            }
            // ViewModel의 errorMessage가 변경될 때 Alert을 표시
            .alert("Error", isPresented: $showErrorAlert, actions: {
                Button("OK") {
                    viewModel.clearError() // OK를 누르면 ViewModel의 에러 상태도 초기화
                }
            }, message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            })
            .onChange(of: viewModel.errorMessage) {
                showErrorAlert = viewModel.errorMessage != nil
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            // 다른 탭으로 이동하는 등 뷰가 사라질 때 녹음 중이면 자동으로 중지
            if viewModel.isListening {
                viewModel.toggleVoiceListening()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// 대화 목록을 표시하는 스크롤 뷰
    private var conversationHistoryView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatMessageView(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            // 메시지 배열의 개수가 변경될 때마다 맨 아래로 스크롤
            .onChange(of: viewModel.messages.count) {
                if let lastMessageID = viewModel.messages.last?.id {
                    withAnimation(.spring()) {
                        proxy.scrollTo(lastMessageID, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    /// 하단의 텍스트 및 음성 입력 UI
    private var promptArea: some View {
        VStack(spacing: 12) {
            // 음성 녹음 중일 때는 인식된 텍스트를 표시
            if viewModel.isListening {
                Text(viewModel.transcribedText.isEmpty ? "Listening..." : viewModel.transcribedText)
                    .font(.body.italic())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .frame(minHeight: 50)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .transition(.opacity)
            } else {
                // 평상시에는 텍스트 입력 필드를 표시
                HStack {
                    TextField(
                        "Ask about your photos, or tap the mic...",
                        text: $viewModel.transcribedText, // 텍스트와 음성 입력을 하나의 State로 관리
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    
                    // 입력된 텍스트가 있을 때만 전송 버튼 표시
                    if !viewModel.transcribedText.isEmpty {
                        Button(action: sendTextMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(viewModel.isGenerating)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(20)
                .transition(.opacity)
            }
            
            // 중앙 마이크 버튼
            Button(action: {
                // 버튼을 누르면 음성 입력을 토글
                viewModel.toggleVoiceListening()
            }) {
                Image(systemName: "mic.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(20)
                    .background(viewModel.isListening ? Color.red : Color(red: 0.25, green: 0.25, blue: 0.25))
                    .clipShape(Circle())
                    .overlay(
                        // 녹음 중일 때 퍼지는 애니메이션 효과
                        Circle()
                            .stroke(Color.white, lineWidth: viewModel.isListening ? 2 : 0)
                            .scaleEffect(viewModel.isListening ? 1.5 : 1.0)
                            .opacity(viewModel.isListening ? 0.0 : 1.0)
                            .animation(
                                viewModel.isListening ? .easeInOut(duration: 1.5).repeatForever(autoreverses: false) : .default,
                                value: viewModel.isListening
                            )
                    )
            }
            
            // Close 버튼 (기능은 추후 구현)
            Button("Close") { }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 5)
        }
        .padding()
        .background(.black.opacity(0.9))
    }
    
    /// 텍스트 메시지를 전송하는 헬퍼 함수
    private func sendTextMessage() {
        let prompt = viewModel.transcribedText
        viewModel.transcribedText = "" // 입력창 비우기
        Task {
            await viewModel.processUserQuery(text: prompt)
        }
    }
}

// MARK: - Chat Message View

struct ChatMessageView: View {
    // Message가 ObservableObject이므로 @ObservedObject를 사용해
    // content의 실시간 변경(스트리밍)을 감지합니다.
    @ObservedObject var message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 50) }
            
            if message.isLoading {
                ProgressView()
                    .padding(12)
                    .background(Color.gray.opacity(0.4))
                    .cornerRadius(16)
            } else {
                Text(message.text)
                    .padding(12)
                    .background(message.isFromUser ? Color.blue : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .textSelection(.enabled)
            }
            
            if !message.isFromUser { Spacer(minLength: 50) }
        }
        .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
    }
}

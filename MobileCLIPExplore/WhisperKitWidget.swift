import SwiftUI

// WhisperKit 위젯 뷰
struct WhisperKitWidget: View {
    @StateObject private var whisperManager = WhisperKitManager()
    @State private var showTranscription = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 메인 음성인식 버튼
            Button(action: {
                if whisperManager.isRecording {
                    whisperManager.stopRecording()
                } else {
                    whisperManager.startRecording()
                }
            }) {
                VStack {
                    Image(systemName: whisperManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(whisperManager.isRecording ? .red : .blue)
                    
                    Text(whisperManager.isRecording ? "녹음 중지" : "음성 인식")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .disabled(whisperManager.isLoading)
            .opacity(whisperManager.isLoading ? 0.6 : 1.0)
            
            // 로딩 인디케이터
            if whisperManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("모델 로딩 중...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // 전사 결과 보기 버튼
            if !whisperManager.transcriptionText.isEmpty && whisperManager.transcriptionText != "녹음 중..." {
                Button("전사 결과 보기") {
                    showTranscription = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .sheet(isPresented: $showTranscription) {
            TranscriptionResultView(text: whisperManager.transcriptionText)
        }
    }
}

// 전사 결과 뷰
struct TranscriptionResultView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("음성 인식 결과")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(text)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

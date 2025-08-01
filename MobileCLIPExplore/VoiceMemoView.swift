// VoiceMemoView.swift

import SwiftUI

struct VoiceMemoView: View {
    // 이전 뷰로부터 전달받는 Moment 데이터
    @Binding var moment: Moment
    
    // 이 뷰의 상태와 로직을 관리하는 ViewModel
    @StateObject private var viewModel = VoiceMemoViewModel()
    
    // 화면을 닫기 위한 Environment 변수
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // MARK: - Representative Image
                PhotoAssetView(identifier: moment.representativeAssetId)
                    .aspectRatio(4/3, contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(12)
                
                // MARK: - Transcribed Text Display
                ScrollView {
                    Text(viewModel.transcribedText.isEmpty ? (viewModel.hasRecording ? "Tap play to listen or re-record." : "Press the microphone to start recording...") : viewModel.transcribedText)
                        .font(.body)
                        .foregroundColor(viewModel.transcribedText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                        .padding()
                }
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                
                // MARK: - Recording Visualizer
                // 녹음 중일 때만 마이크 입력 레벨을 표시
                if viewModel.isRecording {
                    ProgressView(value: viewModel.audioLevel)
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .shadow(color: .red.opacity(0.5), radius: 5)
                }
                
                Spacer()
                
                // MARK: - Control Buttons
                HStack(spacing: 40) {
                    // 재생/중지 버튼
                    Button(action: viewModel.togglePlayback) {
                        Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(viewModel.hasRecording ? .white : .gray)
                    }
                    .disabled(!viewModel.hasRecording || viewModel.isRecording)
                    
                    // 녹음/중지 버튼
                    Button(action: { viewModel.toggleRecording(for: moment.id) }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(viewModel.isRecording ? Color.red : Color.blue)
                            .clipShape(Circle())
                            .shadow(color: (viewModel.isRecording ? Color.red : Color.blue).opacity(0.6), radius: 10)
                    }
                    .disabled(viewModel.isPlaying) // 재생 중에는 녹음 불가
                    
                    // 삭제 버튼 (미구현)
                    Button(action: {
                        // TODO: 삭제 로직 구현 (파일 삭제 및 상태 초기화)
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.title)
                            .foregroundColor(viewModel.hasRecording ? .white : .gray)
                    }
                    .disabled(!viewModel.hasRecording || viewModel.isRecording)
                }
                .padding(.bottom, 40)
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Voice Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // MARK: - Navigation Bar Buttons
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // ViewModel에 녹음 파일이 있을 경우, 해당 경로와 캡션을 Moment에 저장
                        if viewModel.hasRecording, let fileURL = viewModel.audioFileURL {
                            moment.voiceMemoPath = fileURL.lastPathComponent
                            
                            // 캡션이 비어있고, 음성 인식 텍스트가 있다면 자동으로 채워넣기
                            if (moment.caption ?? "").isEmpty && !viewModel.transcribedText.isEmpty {
                                moment.caption = viewModel.transcribedText
                            }
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 뷰가 나타날 때, 기존 녹음 파일이 있는지 ViewModel을 통해 확인
                viewModel.setup(with: moment.voiceMemoPath)
            }
            // ViewModel에서 발생하는 에러 메시지를 Alert으로 표시
            .alert(item: $viewModel.alertMessage) { message in
                Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Alert 메시지를 Identifiable하게 만들기 위한 확장
extension String: Identifiable {
    public var id: String { self }
}

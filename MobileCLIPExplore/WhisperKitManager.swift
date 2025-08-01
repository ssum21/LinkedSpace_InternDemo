import SwiftUI
import AVFoundation
import WhisperKit

// WhisperKit 매니저 클래스
@MainActor
class WhisperKitManager: ObservableObject {
    @Published var isRecording = false
    @Published var transcriptionText = ""
    @Published var isLoading = false
    @Published var whisperKit: WhisperKit?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine = AVAudioEngine()
    private var recordingURL: URL?
    
    init() {
        setupWhisperKit()
        requestMicrophonePermission()
    }
    
    private func setupWhisperKit() {
        Task {
            do {
                self.isLoading = true
                
                // WhisperKit 초기화 (기본 모델 사용)
                let pipe = try await WhisperKit()
                
                self.whisperKit = pipe
                self.isLoading = false
                print("WhisperKit 초기화 완료")
            } catch {
                self.isLoading = false
                print("WhisperKit 초기화 실패: \(error)")
            }
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("마이크 권한 허용됨")
            } else {
                print("마이크 권한 거부됨")
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording.wav")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String : Any]
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            transcriptionText = "녹음 중..."
        } catch {
            print("녹음 시작 실패: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        
        // 녹음 완료 후 전사 시작
        transcribeAudio()
    }
    
    private func transcribeAudio() {
        guard let recordingURL = recordingURL,
              let whisperKit = whisperKit else {
            transcriptionText = "오류: WhisperKit이 초기화되지 않았습니다"
            return
        }
        
        transcriptionText = "전사 중..."
        
        Task {
            do {
                let results = try await whisperKit.transcribe(audioPath: recordingURL.path)
                
                // results는 [TranscriptionResult] 배열이므로 첫 번째 결과의 text를 가져옵니다
                if let firstResult = results.first {
                    self.transcriptionText = firstResult.text
                } else {
                    self.transcriptionText = "전사 결과를 가져올 수 없습니다"
                }
            } catch {
                self.transcriptionText = "전사 오류: \(error.localizedDescription)"
            }
        }
    }
}

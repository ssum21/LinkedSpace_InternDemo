// VoiceMemoViewModel.swift

import SwiftUI
import AVFoundation
import Speech

@MainActor
class VoiceMemoViewModel: ObservableObject {
    // MARK: - Published Properties for UI
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var transcribedText = ""
    @Published var audioLevel: Float = 0.0
    @Published private(set) var hasRecording = false
    @Published var alertMessage: String?
    
    // MARK: - Audio Components
    private var audioSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private(set) var audioFileURL: URL?
    private var audioLevelTimer: Timer?
    
    init() {
        self.audioSession = AVAudioSession.sharedInstance()
    }
    
    // MARK: - Core Logic
    
    func toggleRecording(for momentID: UUID) {
        if isRecording {
            stopRecording()
        } else {
            startRecording(for: momentID)
        }
    }
    
    func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        } else {
            guard let url = self.audioFileURL, hasRecording else { return }
            do {
                try audioSession.setCategory(.playback) // 재생을 위한 카테고리 설정
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                isPlaying = true
            } catch {
                alertMessage = "Error playing audio: \(error.localizedDescription)"
            }
        }
    }
    
    // ▼▼▼ [에러 1 해결] if let을 올바르게 수정 ▼▼▼
    func setup(with voiceMemoPath: String?) {
        if let path = voiceMemoPath {
            let url = getURL(for: path)
            if FileManager.default.fileExists(atPath: url.path) {
                self.audioFileURL = url
                self.hasRecording = true
            }
        }
    }

    // MARK: - Private Helper Functions
    
    func startRecording(for momentID: UUID) {
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] granted in
            DispatchQueue.main.async {
                if granted {
                    self.beginRecording(for: momentID)
                } else {
                    self.alertMessage = "Microphone access was denied."
                }
            }
        }
    }
    
    func beginRecording(for momentID: UUID) {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            
            let fileName = "\(momentID.uuidString).m4a"
            self.audioFileURL = getURL(for: fileName)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            guard let url = audioFileURL else {
                alertMessage = "Failed to create audio file URL."
                return
            }
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            startMonitoringAudioLevel() // 이제 이 함수가 존재합니다.
            
        } catch {
            alertMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioLevelTimer?.invalidate()
        
        isRecording = false
        hasRecording = true
        
        // 녹음이 끝난 후, 음성 인식을 시작합니다.
        transcribeAudio()
    }
    
    // ▼▼▼ [에러 2 해결] 누락되었던 함수 추가 ▼▼▼
    private func startMonitoringAudioLevel() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            self.audioRecorder?.updateMeters()
            let power = self.audioRecorder?.averagePower(forChannel: 0) ?? -160.0
            // 파워 값을 0.0 ~ 1.0 범위로 정규화
            self.audioLevel = self.normalizeAudioLevel(power: power)
        }
    }
    
    private func normalizeAudioLevel(power: Float) -> Float {
        let minDb: Float = -60.0
        if power < minDb {
            return 0.0
        } else if power >= 0.0 {
            return 1.0
        } else {
            return (power - minDb) / (0.0 - minDb)
        }
    }
    
    // MARK: - Speech to Text (녹음 후 파일 기반 인식)
    
    // ▼▼▼ [에러 3 해결] 파일 기반으로 음성을 인식하는 방식으로 변경 ▼▼▼
    private func transcribeAudio() {
        guard let url = audioFileURL else {
            alertMessage = "Audio file URL not found for transcription."
            return
        }
        
        requestSpeechAuthorization { [weak self] authorized in
            guard let self = self, authorized else {
                self?.alertMessage = "Speech recognition permission was denied."
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: url)
            
            speechRecognizer?.recognitionTask(with: request) { (result, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self.alertMessage = "Transcription failed: \(error.localizedDescription)"
                        return
                    }
                    if let result = result {
                        self.transcribedText = result.bestTranscription.formattedString
                    }
                }
            }
        }
    }
    
    private func requestSpeechAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
    
    // MARK: - File Management
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getURL(for fileName: String) -> URL {
        getDocumentsDirectory().appendingPathComponent(fileName)
    }
}

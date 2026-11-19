import Foundation
import Speech
import AVFoundation

@MainActor
final class VoiceInputService: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-EG")) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func toggleRecording(onUpdate: @escaping (String) -> Void) {
        if isRecording {
            stopRecording()
        } else {
            startRecording(onUpdate: onUpdate)
        }
    }

    func startRecording(onUpdate: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard status == .authorized, let self else { return }
                self.beginSession(onUpdate: onUpdate)
            }
        }
    }

    private func beginSession(onUpdate: @escaping (String) -> Void) {
        stopRecording()
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
        isRecording = true

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    let text = result.bestTranscription.formattedString
                    self?.transcript = text
                    onUpdate(text)
                }
                if error != nil || (result?.isFinal ?? false) {
                    self?.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        recognitionTask?.cancel()
        request = nil
        recognitionTask = nil
        isRecording = false
    }
}

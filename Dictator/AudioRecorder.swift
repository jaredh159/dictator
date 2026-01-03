import AppKit
import AVFoundation
import Foundation
import os.log

private let log = Logger(subsystem: "com.jaredh159.dictator", category: "AudioRecorder")

@MainActor
class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var isCleaningUp = false
    @Published var transcription: String?
    @Published var recordingURL: URL?
    @Published var currentPersonality: Personality?

    private var audioRecorder: AVAudioRecorder?
    private let whisperService = WhisperService()
    private let cleanupService = TextCleanupService()

    var onComplete: (() -> Void)?

    private var recordingsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
    }

    init() {
        createRecordingsDirectoryIfNeeded()
        requestMicrophonePermission()
    }

    private func createRecordingsDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(
            at: recordingsDirectory,
            withIntermediateDirectories: true
        )
        log.info("Recordings directory: \(self.recordingsDirectory.path, privacy: .public)")
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            log.info("Microphone permission granted: \(granted)")
        }
    }

    func startRecording() {
        let filename = "recording-\(Date().timeIntervalSince1970).m4a"
        let url = recordingsDirectory.appendingPathComponent(filename)
        log.info("Starting recording to: \(url.path, privacy: .public)")

        // Settings optimized for speech transcription
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,  // 16kHz is ideal for speech recognition
            AVNumberOfChannelsKey: 1,  // Mono for speech
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            let started = audioRecorder?.record() ?? false
            log.info("Recording started: \(started)")
            isRecording = true
            recordingURL = url
        } catch {
            log.error("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        log.info("Recording stopped")

        guard let url = recordingURL else {
            log.error("No recording URL available")
            return
        }

        // Check file exists and size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int
        {
            log.info("Recording file size: \(size) bytes")
        } else {
            log.error("Could not get file attributes")
        }

        isTranscribing = true
        transcription = nil

        let prompt = currentPersonality?.prompt

        Task {
            do {
                let rawText = try await whisperService.transcribe(audioURL: url)
                log.info("Transcription complete: \(rawText, privacy: .public)")

                self.isTranscribing = false
                self.isCleaningUp = true

                let cleanedText = try await cleanupService.cleanup(text: rawText, prompt: prompt)
                self.transcription = cleanedText
                self.copyToClipboard(cleanedText)
                log.info("Cleanup complete, copied to clipboard: \(cleanedText, privacy: .public)")
                self.onComplete?()
            } catch {
                log.error("Processing failed: \(error.localizedDescription)")
                self.transcription = "Error: \(error.localizedDescription)"
            }
            self.isTranscribing = false
            self.isCleaningUp = false
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

import SwiftUI

struct ContentView: View {
    @ObservedObject var recorder: AudioRecorder

    var body: some View {
        HStack(spacing: 12) {
            if recorder.isRecording {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
            } else {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 10, height: 10)
            }

            Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusText: String {
        if recorder.isRecording { return "Recording..." }
        if recorder.isTranscribing { return "Transcribing..." }
        if recorder.isCleaningUp { return "Cleaning up..." }
        return "Ready"
    }
}

#Preview {
    ContentView(recorder: AudioRecorder())
}

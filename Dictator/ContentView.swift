import SwiftUI

struct ContentView: View {
    @ObservedObject var recorder: AudioRecorder

    var body: some View {
        HStack(spacing: 0) {
            Text((recorder.currentPersonality?.name ?? "").uppercased())
                .font(.system(size: 11, weight: .medium))
                .italic()
                .foregroundStyle(Color.gray.opacity(0.7))
                .frame(width: 70, alignment: .leading)

            HStack(spacing: 12) {
                if recorder.isRecording {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                } else {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 8, height: 8)
                }

                Text(statusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .frame(width: 120, alignment: .leading)
        }
        .padding(.horizontal, 16)
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

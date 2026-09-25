#if os(iOS)
import CorgifyCore
import SwiftUI

@available(iOS 18.4, *)
@main
struct CorgifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

@available(iOS 18.4, *)
struct ContentView: View {

    @State private var model = CorgifyViewModel()
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .idle:
                    idleView
                case .analyzing:
                    progressView("Reading the face...")
                case .generating:
                    progressView("Drawing your corgi...")
                case .finished:
                    resultView
                case .failed(let message):
                    failureView(message)
                }
            }
            .navigationTitle("Corgify")
        }
    }

    private var idleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Take a photo of someone and see them as a corgi.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            Button("Take Photo") { showCamera = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func progressView(_ label: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(label).foregroundStyle(.secondary)
        }
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            if let image = model.generatedImage {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()
            }
            if let prompt = model.prompt {
                // Showing the prompt keeps the mapping legible rather than
                // feeling like a black box.
                Text(prompt)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Button("Try Another") { model.reset() }
                .buttonStyle(.bordered)
        }
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Try Again") { model.reset() }
                .buttonStyle(.borderedProminent)
        }
    }
}
#endif

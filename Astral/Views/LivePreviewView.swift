import SwiftUI
import WebKit

struct LivePreviewView: View {
    @EnvironmentObject var appState: AppState
    @State private var urlString: String = "https://antigravity.google.com/"
    @State private var desktopViewport = false
    @State private var reloadToken = UUID()

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("رابط المعاينة أو Antigravity Remote", text: $urlString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .astralGlassCapsule(tint: Color.black.opacity(0.25))
                    .environment(\.layoutDirection, .leftToRight)

                Button {
                    desktopViewport.toggle()
                    reloadToken = UUID()
                } label: {
                    Image(systemName: desktopViewport ? "desktopcomputer" : "iphone")
                        .foregroundStyle(AstralPalette.cyanGlow)
                        .frame(width: 36, height: 36)
                        .astralGlassCapsule()
                }

                Button {
                    reloadToken = UUID()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .astralGlassCapsule()
                }
            }
            .padding(.horizontal, 14)

            AstralWebView(urlString: urlString, desktopMode: desktopViewport)
                .id(reloadToken)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AstralPalette.glassRim, lineWidth: 1)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 86)
        }
        .onAppear {
            if let projURL = appState.activeProject.previewURL, !projURL.isEmpty {
                urlString = projURL
            }
        }
    }
}

struct AstralWebView: UIViewRepresentable {
    let urlString: String
    let desktopMode: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if desktopMode {
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        } else {
            webView.customUserAgent = nil
        }
        if let url = URL(string: urlString), webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}

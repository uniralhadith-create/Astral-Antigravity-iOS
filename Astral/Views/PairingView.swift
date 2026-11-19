import SwiftUI
import AVFoundation

struct PairingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var magicLinkText = ""
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            ZStack {
                AstralAmbientBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        AstralMascotMotionView(size: 100, isThinking: appState.connectionState == .connecting)

                        VStack(spacing: 6) {
                            Text("ربط جهازك بـ Astral")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("شغّل `npx astral-connector` على جهازك ثم امسح رمز QR أو الصق Magic Link للاتصال المباشر والمجاني.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)

                        if showScanner {
                            QRScannerRepresentable { scanned in
                                showScanner = false
                                if let url = URL(string: scanned) {
                                    appState.handleDeepLink(url)
                                    dismiss()
                                }
                            }
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(AstralPalette.cyanGlow, lineWidth: 1.5))
                            .padding(.horizontal, 16)
                        } else {
                            Button {
                                showScanner = true
                            } label: {
                                Label("مسح رمز QR من شاشة الكمبيوتر", systemImage: "qrcode.viewfinder")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(AstralPalette.iridescence, in: Capsule())
                            }
                            .padding(.horizontal, 16)
                        }

                        // Magic Link Manual Paste
                        VStack(alignment: .leading, spacing: 8) {
                            Text("أو الصق رابط Magic Link:")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.85))
                            TextField("astral://pair?ws=ws://192.168.1.5:7788&token=...", text: $magicLinkText)
                                .font(.caption.monospaced())
                                .foregroundStyle(.white)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(12)
                                .astralGlass(cornerRadius: 14)
                                .environment(\.layoutDirection, .leftToRight)

                            Button("اتصال عبر الرابط") {
                                if let url = URL(string: magicLinkText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                    appState.handleDeepLink(url)
                                    dismiss()
                                }
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .astralGlassCapsule()
                            .disabled(magicLinkText.isEmpty)
                        }
                        .padding(16)
                        .astralGlass(cornerRadius: 22)
                        .padding(.horizontal, 16)

                        // Saved Computers
                        if !appState.pairedComputers.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("الأجهزة المحفوظة")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white.opacity(0.8))
                                ForEach(appState.pairedComputers) { pc in
                                    Button {
                                        appState.pairAndConnect(pc)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Image(systemName: "desktopcomputer")
                                                .foregroundStyle(AstralPalette.cyanGlow)
                                            VStack(alignment: .leading) {
                                                Text(pc.name)
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(.white)
                                                Text(pc.wsURL)
                                                    .font(.caption2.monospaced())
                                                    .foregroundStyle(.white.opacity(0.6))
                                            }
                                            Spacer()
                                            Image(systemName: "bolt.horizontal.circle.fill")
                                                .foregroundStyle(AstralPalette.emeraldStatus)
                                        }
                                        .padding(12)
                                        .astralGlass(cornerRadius: 16)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("الاقتران بـ Antigravity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCodeScanned: onCodeScanned) }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return controller }

        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = UIScreen.main.bounds
        preview.videoGravity = .resizeAspectFill
        controller.view.layer.addSublayer(preview)
        context.coordinator.session = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var session: AVCaptureSession?
        let onCodeScanned: (String) -> Void
        private var didScan = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !didScan,
                  let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = obj.stringValue else { return }
            didScan = true
            session?.stopRunning()
            onCodeScanned(value)
        }
    }
}

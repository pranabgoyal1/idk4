//
//  ScanView.swift
//  PitampuraBites
//
//  Full-screen QR scanner: live AVFoundation camera feed with lime corner
//  brackets and a sweeping scan line, flashlight toggle, and a bottom panel
//  listing every onboarded outlet with the user's real-time distance, a
//  nearby filter, search, and an in-app map ("locate on maps"). Scanning an
//  outlet's code only opens its page when the user is within 200 m of it.
//

import SwiftUI
import AVFoundation
import MapKit

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var camera = CameraController()
    @State private var cameraStatus: CameraController.Status = .starting
    @State private var torchIsOn = false
    @State private var scanLineOffset: CGFloat = -120
    @State private var bracketsPulse = false
    @State private var searchText = ""
    @State private var nearbyOnly = false
    @State private var showMap = false
    @State private var showAreaPicker = false
    @State private var detailShop: Shop?
    @State private var banner: Banner?

    private var location: LocationService { appState.location }

    /// Transient scan feedback ("too far", "unknown code") shown above the panel.
    private struct Banner: Equatable {
        let text: String
        let isError: Bool
    }

    var body: some View {
        ZStack {
            cameraLayer
            controls
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        // The panel as a bottom safe-area inset lets the scan frame centre
        // itself in the true remaining space (no hard-reserved heights).
        .safeAreaInset(edge: .bottom, spacing: 0) { panel }
        .animation(.spring(duration: 0.4), value: cameraStatus)
        .fullScreenCover(item: $detailShop) { shop in
            ShopDetailView(shop: shop)
        }
        .sheet(isPresented: $showMap) {
            NearbyMapView(
                userCoordinate: location.currentLocation?.coordinate,
                locationService: location
            )
        }
        .sheet(isPresented: $showAreaPicker) {
            AreaPickerSheet(selected: location.displayLocation) { name in
                location.setManualLocality(name)
            }
            .presentationDetents([.medium])
            .presentationBackground(Color.appBackground)
        }
        .onAppear {
            camera.onQRCode = { handleQRCode($0) }
            camera.onStatus = { status in cameraStatus = status }
            camera.start()
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                scanLineOffset = 120
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                bracketsPulse = true
            }
        }
        .onDisappear {
            camera.stop()
            camera.setTorch(false)
            torchIsOn = false
        }
    }

    // MARK: - QR handling

    /// Opens the scanned shop only when the user is within 200 m of it.
    private func handleQRCode(_ payload: String) {
        guard detailShop == nil else { return }
        guard let shop = MockData.shop(forQRCode: payload) else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            showBanner("That QR isn't a Pitampura Bites outlet", isError: true)
            return
        }
        guard let here = location.currentLocation else {
            showBanner("Turn on your location to unlock outlet scans", isError: true)
            return
        }
        let distance = here.distance(from: CLLocation(latitude: shop.latitude, longitude: shop.longitude))
        guard distance <= 200 else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            showBanner(
                "Too far — \(shop.name) is \(LocationService.formatDistance(distance)) away. Get within 200 m to scan.",
                isError: true
            )
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        detailShop = shop
    }

    private func showBanner(_ text: String, isError: Bool) {
        let message = Banner(text: text, isError: isError)
        withAnimation(.spring(duration: 0.4)) { banner = message }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard banner == message else { return }
            withAnimation { banner = nil }
        }
    }

    // MARK: - Layers

    @ViewBuilder
    private var cameraLayer: some View {
        switch cameraStatus {
        case .running:
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.35).ignoresSafeArea())
        case .starting:
            Color.black.ignoresSafeArea()
            ProgressView().tint(.white).scaleEffect(1.2)
        case .denied, .unavailable:
            cameraFallback
        }
    }

    /// Shown when the camera is denied or absent (e.g. no camera backend).
    private var cameraFallback: some View {
        Color.black.ignoresSafeArea()
            .overlay {
                VStack(spacing: 14) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.appTextSecondary)
                    Text(cameraStatus == .denied ? "Camera access needed" : "Camera unavailable")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("The search and map below still work —\nyou can reach every onboarded outlet there.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)

                    if cameraStatus == .denied {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open Settings")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 28)
                                .frame(height: 48)
                                .background(Color.lime, in: .capsule)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 40)
            }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 24)
                .padding(.top, 8)

            titleBlock
                .padding(.top, 18)

            Spacer(minLength: 16)

            if let banner {
                bannerView(banner)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            scanFrame
                .frame(width: 264, height: 264)
                .padding(.bottom, 8)

            Spacer(minLength: 16)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .glassPanel(in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close scanner")

            Spacer()

            Button {
                torchIsOn.toggle()
                camera.setTorch(torchIsOn)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: torchIsOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(torchIsOn ? Color.lime : .white)
                    .frame(width: 44, height: 44)
                    .glassPanel(in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(torchIsOn ? "Turn flashlight off" : "Turn flashlight on")
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 10) {
            (Text("Scan ").foregroundStyle(.white) + Text("QR").foregroundStyle(Color.lime))
                .font(.system(size: 34, weight: .bold))
            // Two deterministic lines matching the reference art.
            VStack(spacing: 2) {
                Text("Point your camera at the QR code")
                Text("at the outlet to view, rate or add a new place.")
            }
            .font(.system(size: 16))
            .foregroundStyle(.white.opacity(0.85))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
        }
    }

    private func bannerView(_ message: Banner) -> some View {
        Text(message.text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(message.isError ? Color.hotPink : .black)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                (message.isError ? Color.appSurface : Color.lime),
                in: .capsule
            )
            .overlay {
                if message.isError {
                    Capsule().strokeBorder(Color.hotPink.opacity(0.5), lineWidth: 1)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(message.text)
    }

    /// Lime corner brackets with a sweeping scan line and a subtle pulse.
    private var scanFrame: some View {
        ZStack {
            ScanBrackets()
                .stroke(
                    Color.lime,
                    style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )
                .scaleEffect(bracketsPulse ? 1.035 : 1)
                .shadow(color: Color.lime.opacity(0.45), radius: 8)

            Capsule()
                .fill(Color.lime)
                .frame(height: 3)
                .frame(maxWidth: 210)
                .offset(y: scanLineOffset)
                .shadow(color: Color.lime.opacity(0.9), radius: 6)
                .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Bottom panel

    private var panel: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 10)

            searchField
            locateButton
            outletList
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(Color.appBackground)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.appTextSecondary)
            TextField("Can't scan? Search outlet name...", text: $searchText)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .glassPanel(in: .rect(cornerRadius: 18))
    }

    private var locateButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showMap = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.lime)
                Text("locate on maps")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .glassPanel(in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Locate onboarded outlets on the map")
    }

    private var outletList: some View {
        VStack(spacing: 8) {
            HStack {
                Text(searchText.isEmpty ? "Onboarded near you" : "All onboarded outlets")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                Spacer()
                nearbyChip
            }

            if location.currentLocation == nil {
                areaHintRow
            }

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(visibleOutlets, id: \.shop.id) { entry in
                        outletRow(entry)
                    }
                    if visibleOutlets.isEmpty {
                        Text(nearbyOnly ? "No onboarded outlets within 2 km" : "No outlets match \"\(searchText)\"")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appTextSecondary)
                            .padding(.vertical, 24)
                    }
                }
            }
            .frame(height: 168)
            .scrollIndicators(.hidden)
        }
    }

    /// Without a fix (sandboxed preview) distances can't compute — offer the
    /// manual area picker, which anchors distances to the picked locality.
    private var areaHintRow: some View {
        Button {
            showAreaPicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("Pick your area for accurate distances")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(Color.lime, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pick your area for accurate distances")
    }

    private var nearbyChip: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(duration: 0.3)) { nearbyOnly.toggle() }
        } label: {
            Text("Nearby")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(nearbyOnly ? .black : Color.appTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .chipSurface(isSelected: nearbyOnly)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(nearbyOnly ? "Nearby filter on" : "Nearby filter off")
    }

    private var visibleOutlets: [(shop: Shop, distance: CLLocationDistance?)] {
        var outlets = MockData.shops.map { shop in
            (shop: shop, distance: location.distanceMeters(to: shop.coordinate))
        }
        // Closest first, live as the user's fix updates.
        outlets.sort { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) }
        if nearbyOnly {
            outlets = outlets.filter { ($0.distance ?? .greatestFiniteMagnitude) <= 2000 }
        }
        if !searchText.isEmpty {
            outlets = outlets.filter { entry in
                [entry.shop.name, entry.shop.category, entry.shop.locality].contains {
                    $0.localizedStandardContains(searchText)
                }
            }
        }
        return outlets
    }

    private func outletRow(_ entry: (shop: Shop, distance: CLLocationDistance?)) -> some View {
        Button {
            detailShop = entry.shop
        } label: {
            HStack(spacing: 12) {
                Image(entry.shop.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .clipShape(.rect(cornerRadius: 12))
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.shop.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(entry.shop.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Real-time straight-line distance, lime when in scan range.
                if let distance = entry.distance {
                    Text(LocationService.formatDistance(distance))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(distance <= 200 ? Color.lime : Color.appTextSecondary)
                        .monospacedDigit()
                } else {
                    Text(entry.shop.locality)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(.vertical, 7)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            entry.distance.map {
                "\(entry.shop.name), \(LocationService.formatDistance($0)) away"
            } ?? entry.shop.name
        )
    }
}

// MARK: - Camera pipeline

/// Live capture session + QR metadata detection. Discovers the built-in and
/// injected external cameras; surfaces permission/absence through `onStatus`.
@MainActor
final class CameraController: NSObject {
    enum Status {
        case starting, running, denied, unavailable
    }

    let session = AVCaptureSession()

    /// Called on the main actor when a QR payload is detected.
    nonisolated(unsafe) var onQRCode: ((String) -> Void)?
    nonisolated(unsafe) var onStatus: ((Status) -> Void)?

    private let output = AVCaptureMetadataOutput()
    private var isConfigured = false
    nonisolated(unsafe) private var lastScanTime: Date?

    func start() {
        Task {
            let permission = AVCaptureDevice.authorizationStatus(for: .video)
            switch permission {
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                guard granted else {
                    onStatus?(.denied)
                    return
                }
            case .denied, .restricted:
                onStatus?(.denied)
                return
            default:
                break
            }

            configureIfNeeded()
            guard isConfigured else { return }
            session.startRunning()
            onStatus?(.running)
        }
    }

    func stop() {
        guard isConfigured, session.isRunning else { return }
        session.stopRunning()
    }

    func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        guard let device = discovery.devices.first,
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            onStatus?(.unavailable)
            return
        }
        session.addInput(input)

        guard session.canAddOutput(output) else {
            onStatus?(.unavailable)
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        isConfigured = true
    }
}

extension CameraController: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let code = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject })
            .first(where: { $0.type == AVMetadataObject.ObjectType.qr }),
            let payload = code.stringValue else { return }

        // Ignore repeats of the same code while the UI is still reacting.
        let now = Date()
        if let last = lastScanTime, now.timeIntervalSince(last) < 3 { return }
        lastScanTime = now

        // The delegate queue is .main, so hopping onto the actor is safe.
        MainActor.assumeIsolated {
            self.onQRCode?(payload)
        }
    }
}

/// Aspect-fill preview layer sized to its host view.
private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    fileprivate final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

/// Draws only the four rounded lime corner brackets of the scan frame.
private struct ScanBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 28
        let length: CGFloat = 52
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))

        return path
    }
}

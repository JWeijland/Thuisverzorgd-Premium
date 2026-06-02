import SwiftUI
import AVFoundation
import Combine
import CoreLocation
import Vision
import VisionKit

// MARK: - Flow orchestrator

struct CheckInFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask
    let onComplete: (CheckInRecord) -> Void

    @State private var step: Step = .selfie
    @State private var selfieConfirmed = false
    @State private var capturedSelfie: UIImage? = nil
    @State private var scannedQR: String? = nil

    enum Step { case selfie, qr, gps, done }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                BCColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    stepIndicator
                        .padding(.top, BCSpacing.md)
                        .padding(.bottom, BCSpacing.sm)

                    Group {
                        switch step {
                        case .selfie:
                            SelfieStepView(onConfirmed: handleSelfieConfirmed)
                        case .qr:
                            QRScanStepView(elderlyName: task.elderlyName, onScanned: handleQRScanned)
                        case .gps:
                            GPSVerifyView(
                                task: task,
                                qrPayload: scannedQR ?? "mock://checkin",
                                hasSelfie: selfieConfirmed,
                                selfieImage: capturedSelfie,
                                onComplete: handleGPSDone
                            )
                        case .done:
                            CheckInSuccessView()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.35), value: step)
                }
            }
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == .selfie || step == .qr {
                        Button("Annuleer") { dismiss() }
                            .tint(BCColors.primary)
                    }
                }
            }
        }
    }

    // MARK: - Step handlers

    private func handleSelfieConfirmed(image: UIImage) {
        capturedSelfie = image
        selfieConfirmed = true
        withAnimation { step = .qr }
    }

    private func handleQRScanned(_ payload: String) {
        scannedQR = payload
        withAnimation { step = .gps }
    }

    private func handleGPSDone(_ record: CheckInRecord) {
        withAnimation { step = .done }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            onComplete(record)
        }
    }

    // MARK: - Step indicator

    private var stepIndicator: some View {
        let steps: [Step] = [.selfie, .qr, .gps]
        let currentIndex = steps.firstIndex(of: step) ?? 0

        return HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { i in
                Capsule()
                    .fill(i <= currentIndex ? BCColors.primary : BCColors.border)
                    .frame(height: 4)
                    .animation(.easeInOut, value: step)
            }
        }
        .padding(.horizontal, BCSpacing.xl)
    }
}

extension CheckInFlowView.Step {
    var title: String {
        switch self {
        case .selfie: return "Selfie"
        case .qr:     return "QR-code"
        case .gps:    return "Locatie"
        case .done:   return "Ingecheckt"
        }
    }
}

// MARK: - Step 1: Selfie

private struct SelfieStepView: View {
    let onConfirmed: (UIImage) -> Void

    @State private var capturedImage: UIImage? = nil
    @State private var showingCamera = false
    @State private var analyzing = false

    var body: some View {
        ScrollView {
            VStack(spacing: BCSpacing.xl) {
                VStack(spacing: BCSpacing.sm) {
                    Image(systemName: "faceid")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(BCColors.primary)
                    Text("Selfie voor check-in")
                        .font(BCTypography.title)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Eenmalig per bezoek. Bevestigt dat jij het bent die incheckt.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, BCSpacing.lg)

                if analyzing {
                    analyzingView
                } else if let img = capturedImage {
                    confirmedView(img)
                } else {
                    cameraPrompt
                }

                Spacer()
            }
            .padding(.horizontal, BCSpacing.lg)
        }
        .sheet(isPresented: $showingCamera) {
            FrontCameraView { image in
                showingCamera = false
                capturedImage = image
                startAnalysis()
            }
        }
    }

    private var cameraPrompt: some View {
        VStack(spacing: BCSpacing.lg) {
            ZStack {
                Circle()
                    .fill(BCColors.surface)
                    .frame(width: 160, height: 160)
                    .overlay(Circle().stroke(BCColors.border, lineWidth: 1.5))
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(BCColors.textTertiary)
            }
            BCPrimaryButton(title: "Neem selfie", icon: "camera.fill") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showingCamera = true
                } else {
                    // Simulator: simuleer direct
                    capturedImage = UIImage(systemName: "person.crop.circle.fill")
                    startAnalysis()
                }
            }
        }
    }

    private var analyzingView: some View {
        VStack(spacing: BCSpacing.md) {
            ZStack {
                Circle()
                    .fill(BCColors.primary.opacity(0.08))
                    .frame(width: 160, height: 160)
                ProgressView()
                    .scaleEffect(1.6)
                    .tint(BCColors.primary)
            }
            Text("Gezicht herkennen…")
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)
        }
    }

    private func confirmedView(_ img: UIImage) -> some View {
        VStack(spacing: BCSpacing.lg) {
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(BCColors.success, lineWidth: 3))
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(BCColors.success)
                    .background(Circle().fill(BCColors.background).padding(2))
            }
            Text("Gezicht herkend")
                .font(BCTypography.bodyEmphasized)
                .foregroundStyle(BCColors.success)
            VStack(spacing: BCSpacing.sm) {
                BCCTAButton(title: "Bevestigen & doorgaan", icon: "arrow.right") {
                    onConfirmed(img)
                }
                BCSecondaryButton(title: "Opnieuw nemen", icon: "arrow.counterclockwise") {
                    capturedImage = nil
                }
            }
        }
    }

    private func startAnalysis() {
        analyzing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            analyzing = false
        }
    }
}

// MARK: - Front camera picker

private struct FrontCameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {}
    }
}

// MARK: - Step 2: QR Scanner

private struct QRScanStepView: View {
    let elderlyName: String
    let onScanned: (String) -> Void

    @State private var showManualInput = false
    @State private var manualCode = ""
    @State private var scanned = false

    private var useRealScanner: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        ZStack {
            if useRealScanner {
                DataScannerRepresentable(onScanned: handleScanned)
                    .ignoresSafeArea()
            } else {
                simulatorFallback
            }

            if useRealScanner {
                scannerOverlay
            }
        }
        .sheet(isPresented: $showManualInput) {
            manualInputSheet
        }
    }

    // Overlay op de camera
    private var scannerOverlay: some View {
        VStack {
            HStack {
                Label("Scan de QR-code op de telefoon van \(elderlyName)", systemImage: "qrcode.viewfinder")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(.white)
                    .padding(.horizontal, BCSpacing.md)
                    .padding(.vertical, BCSpacing.sm)
                    .background(Capsule().fill(.black.opacity(0.55)))
            }
            .padding(.top, BCSpacing.md)

            Spacer()
            finderFrame
            Spacer()

            HStack(spacing: BCSpacing.sm) {
                Button {
                    showManualInput = true
                } label: {
                    Text("Code niet scanbaar?")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(.white)
                        .padding(.horizontal, BCSpacing.md)
                        .padding(.vertical, BCSpacing.sm)
                        .background(Capsule().fill(.black.opacity(0.5)))
                }
                Button {
                    handleScanned("buddycare://demo/\(UUID().uuidString)")
                } label: {
                    Label("Demo", systemImage: "play.fill")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(.white)
                        .padding(.horizontal, BCSpacing.md)
                        .padding(.vertical, BCSpacing.sm)
                        .background(Capsule().fill(BCColors.primary.opacity(0.8)))
                }
            }
            .padding(.bottom, BCSpacing.xl)
        }
    }

    private var finderFrame: some View {
        ZStack {
            // Hoeken
            ForEach(0..<4, id: \.self) { i in
                CornerBracket()
                    .rotationEffect(.degrees(Double(i) * 90))
                    .frame(width: 240, height: 240)
            }
        }
    }

    // Simulator fallback
    private var simulatorFallback: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()
            VStack(spacing: BCSpacing.md) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(BCColors.primary)
                Text("Camera niet beschikbaar")
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Gebruik de simulator-knop om door te gaan.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            BCPrimaryButton(title: "Simuleer QR-scan", icon: "qrcode") {
                handleScanned("buddycare://task/\(UUID().uuidString)")
            }
            BCSecondaryButton(title: "Code handmatig invoeren", icon: "keyboard") {
                showManualInput = true
            }
            Spacer()
        }
        .padding(BCSpacing.lg)
        .background(BCColors.background)
    }

    private var manualInputSheet: some View {
        NavigationStack {
            VStack(spacing: BCSpacing.lg) {
                Text("Vraag \(elderlyName) om de code naast de QR-code op te lezen en voer hem hier in.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, BCSpacing.lg)

                TextField("Code — bijv. 482917", text: $manualCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .font(BCTypography.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCSpacing.lg)

                BCPrimaryButton(title: "Bevestig code", icon: "checkmark.circle.fill") {
                    showManualInput = false
                    handleScanned("buddycare://manual/\(manualCode)")
                }
                .disabled(manualCode.count < 4)
                .padding(.horizontal, BCSpacing.lg)

                Spacer()
            }
            .navigationTitle("Code invoeren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { showManualInput = false }.tint(BCColors.primary)
                }
            }
        }
    }

    private func handleScanned(_ payload: String) {
        guard !scanned else { return }
        scanned = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        onScanned(payload)
    }
}

// MARK: - VisionKit scanner wrapper

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onScanned: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: false,
            isGuidanceEnabled: false,
            isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScanned: onScanned) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScanned: (String) -> Void
        private var fired = false

        init(onScanned: @escaping (String) -> Void) { self.onScanned = onScanned }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard !fired else { return }
            for item in addedItems {
                if case .barcode(let code) = item, let payload = code.payloadStringValue {
                    fired = true
                    dataScanner.stopScanning()
                    onScanned(payload)
                    return
                }
            }
        }
    }
}

// MARK: - Finder corner bracket shape

private struct CornerBracket: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 28
            let t: CGFloat = 3

            Path { path in
                // Top-left corner (rest is rotated by the parent)
                path.move(to: CGPoint(x: 0, y: len))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: len, y: 0))
            }
            .stroke(.white, style: StrokeStyle(lineWidth: t, lineCap: .round))
            .frame(width: w, height: h)
        }
    }
}

// MARK: - Step 3: GPS verify

private struct GPSVerifyView: View {
    let task: ServiceTask
    let qrPayload: String
    let hasSelfie: Bool
    let selfieImage: UIImage?
    let onComplete: (CheckInRecord) -> Void

    @Environment(AppState.self) private var appState
    @StateObject private var locationManager = CheckInLocationManager()
    @State private var uiState: GPSState = .locating
    private let taskService = TaskService()

    enum GPSState { case locating, withinRange, outOfRange, unavailable }

    var body: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()

            switch uiState {
            case .locating:
                locatingView
            case .withinRange:
                resultView(
                    icon: "location.fill",
                    iconColor: BCColors.success,
                    title: "Locatie bevestigd",
                    subtitle: locationManager.distanceText,
                    badgeColor: BCColors.success
                )
            case .outOfRange:
                resultView(
                    icon: "location.slash.fill",
                    iconColor: BCColors.warning,
                    title: "Buiten verwacht bereik",
                    subtitle: "\(locationManager.distanceText) van het adres — toch ingecheckt.",
                    badgeColor: BCColors.warning
                )
            case .unavailable:
                resultView(
                    icon: "location.slash",
                    iconColor: BCColors.textTertiary,
                    title: "GPS niet beschikbaar",
                    subtitle: "Locatie kon niet worden bepaald.",
                    badgeColor: BCColors.textTertiary
                )
            }

            Spacer()
        }
        .padding(BCSpacing.lg)
        .onReceive(locationManager.$result) { result in
            guard let result = result else { return }
            finalize(result)
        }
        .onAppear { locationManager.start(taskCoordinate: task.coordinate) }
    }

    private var locatingView: some View {
        VStack(spacing: BCSpacing.lg) {
            ZStack {
                Circle()
                    .fill(BCColors.primary.opacity(0.08))
                    .frame(width: 120, height: 120)
                ProgressView()
                    .scaleEffect(1.8)
                    .tint(BCColors.primary)
            }
            VStack(spacing: BCSpacing.xs) {
                Text("Locatie controleren")
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Even geduld…")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
            }
        }
    }

    private func resultView(icon: String, iconColor: Color, title: String, subtitle: String, badgeColor: Color) -> some View {
        VStack(spacing: BCSpacing.lg) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.10))
                    .frame(width: 120, height: 120)
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            VStack(spacing: BCSpacing.xs) {
                Text(title)
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
                Text(subtitle)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Text("Check-in wordt afgerond…")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textTertiary)
        }
    }

    private func finalize(_ result: LocationResult) {
        let distance = result.distanceMeters
        withAnimation {
            if result.denied {
                uiState = .unavailable
            } else if let d = distance, d <= 500 {
                uiState = .withinRange
            } else {
                uiState = distance != nil ? .outOfRange : .unavailable
            }
        }
        var record = CheckInRecord(
            timestamp: Date(),
            latitude: result.latitude,
            longitude: result.longitude,
            qrPayload: qrPayload,
            hasSelfie: hasSelfie,
            distanceMeters: result.distanceMeters
        )
        Task {
            // Upload selfie naar Supabase Storage (alleen in real mode met echte buddy)
            if !appState.isDemoMode,
               let buddyId = appState.realUserId,
               let image = selfieImage,
               let jpegData = image.jpegData(compressionQuality: 0.75) {
                record.selfieStorageUrl = try? await taskService.uploadCheckInSelfie(
                    imageData: jpegData,
                    taskId: task.id,
                    buddyId: buddyId
                )
            }
            try? await taskService.markArrived(taskId: task.id, selfieUrl: record.selfieStorageUrl)
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onComplete(record)
                }
            }
        }
    }
}

// MARK: - Location manager (one-shot)

private struct LocationResult {
    let latitude: Double?
    let longitude: Double?
    let distanceMeters: Double?
    let denied: Bool
}

private class CheckInLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var result: LocationResult? = nil
    @Published var distanceText: String = ""

    private let manager = CLLocationManager()
    private var taskCoordinate: CLLocationCoordinate2D? = nil
    private var resolved = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func start(taskCoordinate: CLLocationCoordinate2D? = nil) {
        self.taskCoordinate = taskCoordinate
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            emit(location: nil, denied: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !resolved, let loc = locations.last else { return }
        var distance: Double? = nil
        if let tc = taskCoordinate {
            distance = loc.distance(from: CLLocation(latitude: tc.latitude, longitude: tc.longitude))
            if let d = distance {
                distanceText = d < 1000 ? "\(Int(d.rounded())) m" : String(format: "%.1f km", d / 1000)
            }
        }
        emit(location: loc, denied: false, distance: distance)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        emit(location: nil, denied: false)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            emit(location: nil, denied: true)
        default: break
        }
    }

    private func emit(location: CLLocation?, denied: Bool, distance: Double? = nil) {
        guard !resolved else { return }
        resolved = true
        DispatchQueue.main.async {
            self.result = LocationResult(
                latitude: location?.coordinate.latitude,
                longitude: location?.coordinate.longitude,
                distanceMeters: distance,
                denied: denied
            )
        }
    }
}

extension CheckInLocationManager {
    func start() { start(taskCoordinate: nil) }
}

// MARK: - Success screen

private struct CheckInSuccessView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: BCSpacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(BCColors.success.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(BCColors.success)
            }
            .scaleEffect(scale)
            .opacity(opacity)

            VStack(spacing: BCSpacing.xs) {
                Text("Ingecheckt!")
                    .font(BCTypography.title)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Taak wordt gestart.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
            }
            .opacity(opacity)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

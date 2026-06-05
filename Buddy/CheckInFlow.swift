import SwiftUI
import Combine
import CoreLocation

// MARK: - Flow orchestrator

struct CheckInFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask
    let onComplete: (CheckInRecord) -> Void

    // Vereenvoudigde check-in: alleen aankomst bevestigen (geen selfie / QR).
    @State private var step: Step = .arrival

    enum Step { case arrival, done }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                BCColors.background.ignoresSafeArea()

                Group {
                    switch step {
                    case .arrival:
                        GPSVerifyView(
                            task: task,
                            qrPayload: "mock://checkin",
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
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == .arrival {
                        Button("Annuleer") { dismiss() }
                            .tint(BCColors.primary)
                    }
                }
            }
        }
    }

    private func handleGPSDone(_ record: CheckInRecord) {
        withAnimation { step = .done }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            onComplete(record)
        }
    }
}

extension CheckInFlowView.Step {
    var title: String {
        switch self {
        case .arrival: return "Aankomst bevestigen"
        case .done:    return "Ingecheckt"
        }
    }
}

// MARK: - Step 3: GPS verify

private struct GPSVerifyView: View {
    let task: ServiceTask
    let qrPayload: String
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
        let record = CheckInRecord(
            timestamp: Date(),
            latitude: result.latitude,
            longitude: result.longitude,
            qrPayload: qrPayload,
            distanceMeters: result.distanceMeters
        )
        Task {
            try? await taskService.markArrived(taskId: task.id)
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

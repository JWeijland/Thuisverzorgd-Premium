import SwiftUI
import MapKit

// MARK: - Maps routing

/// Opent Apple Maps met een route naar het adres van de oudere.
func openRouteInMaps(to task: ServiceTask, mode: BuddyNavigationView.TransportMode = .walking) {
    let placemark = MKPlacemark(coordinate: task.coordinate)
    let item = MKMapItem(placemark: placemark)
    item.name = "\(task.elderlyName) — \(task.elderlyAddress)"
    let directionsMode = mode == .walking
        ? MKLaunchOptionsDirectionsModeWalking
        : MKLaunchOptionsDirectionsModeDriving
    item.openInMaps(launchOptions: [
        MKLaunchOptionsDirectionsModeKey: directionsMode
    ])
}

// MARK: - In-app navigatie naar de oudere (in app-thema)

/// Volledig scherm met een in-app route (MapKit) van de buddy naar het adres
/// van de oudere, in de huisstijl. Apple Kaarten blijft beschikbaar als fallback.
struct BuddyNavigationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask

    enum TransportMode: CaseIterable, Identifiable {
        case walking, driving
        var id: Self { self }
        var label: String { self == .walking ? "Lopen" : "Auto" }
        var icon: String { self == .walking ? "figure.walk" : "car.fill" }
        var mkType: MKDirectionsTransportType { self == .walking ? .walking : .automobile }
    }

    @State private var transport: TransportMode = .walking
    @State private var route: MKRoute?
    @State private var isLoading = true
    @State private var errorText: String?
    @State private var cameraPosition: MapCameraPosition = .automatic

    /// Vertrekpunt = de (mock-)locatie van de buddy.
    private var origin: CLLocationCoordinate2D { appState.buddyUser.coordinate }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                map
                    .ignoresSafeArea(edges: .top)
                routeCard
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Navigatie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sluiten") { dismiss() }
                        .tint(BCColors.primary)
                }
            }
            .task(id: transport) { await computeRoute() }
        }
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            Annotation("Start", coordinate: origin) {
                ZStack {
                    Circle().fill(.white)
                    Circle().fill(BCColors.primary).padding(4)
                }
                .frame(width: 22, height: 22)
                .bcSoftShadow(.subtle)
            }
            Annotation(task.elderlyName, coordinate: task.coordinate) {
                ZStack {
                    Circle().fill(BCColors.accent)
                    Image(systemName: "house.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(BCColors.navy900)
                }
                .frame(width: 34, height: 34)
                .bcSoftShadow(.raised)
            }
            if let route {
                MapPolyline(route.polyline)
                    .stroke(BCColors.primary, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .tint(BCColors.primary)
    }

    private var routeCard: some View {
        VStack(spacing: BCSpacing.sm) {
            Picker("Vervoer", selection: $transport) {
                ForEach(TransportMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: BCSpacing.md) {
                Image(systemName: task.category.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(BCColors.primary))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Naar \(task.elderlyName)")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(task.elderlyAddress)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                if isLoading {
                    ProgressView().tint(BCColors.primary)
                } else if let route {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatETA(route.expectedTravelTime))
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.navy900)
                        Text(formatDistance(route.distance))
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                }
            }

            if let errorText {
                Text(errorText)
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let route, let first = route.steps.first(where: { !$0.instructions.isEmpty }) {
                HStack(spacing: BCSpacing.sm) {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(BCColors.accentDark)
                    Text(first.instructions)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textPrimary)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(BCSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surfaceMuted))
            }

            BCSecondaryButton(title: "Open in Apple Kaarten", icon: "map.fill") {
                openRouteInMaps(to: task, mode: transport)
            }
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                .fill(BCColors.surface)
                .bcSoftShadow(.raised)
        )
        .padding(BCSpacing.md)
    }

    private func computeRoute() async {
        isLoading = true
        errorText = nil
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: task.coordinate))
        request.transportType = transport.mkType
        do {
            let response = try await MKDirections(request: request).calculate()
            if let best = response.routes.first {
                route = best
                cameraPosition = .rect(best.polyline.boundingMapRect)
            } else {
                errorText = "Geen route gevonden."
            }
        } catch {
            errorText = "Route kon niet worden geladen. Gebruik Apple Kaarten."
        }
        isLoading = false
    }

    private func formatETA(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int((seconds / 60).rounded()))
        return "\(minutes) min"
    }

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        meters < 1000 ? "\(Int(meters.rounded())) m" : String(format: "%.1f km", meters / 1000)
    }
}

// MARK: - Task detail sheet (tapped from map)

struct TaskDetailSheet: View {
    @Environment(AppState.self) private var appState
    let task: ServiceTask
    let onAccept: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack {
                    Image(systemName: task.category.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(BCColors.primary))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.category.displayName)
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("Bij \(task.elderlyName) — \(task.elderlyAddress)")
                            .font(BCTypography.subheadline)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    Spacer()
                }

                HStack(spacing: BCSpacing.sm) {
                    BCStatusPill(label: "Nieuw · dichtbij", color: BCColors.accentDark, showDot: true)
                    BCStatusPill(label: task.timing.displayName, color: BCColors.primary)
                    Spacer()
                }

                BCCard {
                    HStack(spacing: BCSpacing.sm) {
                        statBox(label: "Afstand", value: "± 1,4 km", color: BCColors.textPrimary)
                        Divider().frame(height: 40)
                        statBox(label: "Dienst", value: task.category.displayName, color: BCColors.primary)
                        Divider().frame(height: 40)
                        statBox(label: "Verdienste", value: task.priceFormatted, color: BCColors.green600)
                    }
                }

                if !task.note.isEmpty {
                    BCCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Bericht van \(task.elderlyName)", systemImage: "text.bubble.fill")
                                .font(BCTypography.captionEmphasized)
                                .foregroundStyle(BCColors.textSecondary)
                            Text(task.note)
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textPrimary)
                        }
                    }
                }

                BCCTAButton(title: "Klus aannemen", icon: "checkmark", iconLeading: true) {
                    onAccept()
                }

                BCSecondaryButton(title: "Naar route bekijken", icon: "map.fill") {
                    openRouteInMaps(to: task)
                }
            }
            .padding(BCSpacing.lg)
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    private func statBox(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
            Text(value)
                .font(BCTypography.title3)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active task — full screen flow

struct TaskInProgressView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask

    @State private var stage: Stage = .onTheWay
    @State private var checklist: [ChecklistItem] = [
        ChecklistItem(text: "Aangebeld en welkom geheten", done: false),
        ChecklistItem(text: "Bezoek gestart en kort gepraat", done: false),
        ChecklistItem(text: "Hoofdtaak uitgevoerd", done: false),
        ChecklistItem(text: "Ruimte netjes achtergelaten", done: false)
    ]
    @State private var note: String = ""
    @State private var showCheckIn = false
    @State private var showCancelConfirm = false
    @State private var showNavigation = false

    enum Stage { case onTheWay, atDoor, inProgress, completing, done }

    var body: some View {
        NavigationStack {
            ZStack {
                BCColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    Group {
                        switch stage {
                        case .onTheWay: onTheWayContent
                        case .atDoor: atDoorContent
                        case .inProgress: inProgressContent
                        case .completing: completingContent
                        case .done: doneContent
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    bottomBar
                }
            }
            .navigationTitle("Actieve taak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }
                        .tint(BCColors.primary)
                }
            }
            .sheet(isPresented: $showCheckIn) {
                CheckInFlowView(task: task) { checkInRecord in
                    showCheckIn = false
                    appState.buddyArrives(checkIn: checkInRecord)
                    stage = .inProgress
                }
            }
            .fullScreenCover(isPresented: $showNavigation) {
                BuddyNavigationView(task: task)
                    .environment(appState)
            }
            .confirmationDialog(
                "Taak annuleren?",
                isPresented: $showCancelConfirm,
                titleVisibility: .visible
            ) {
                Button("Ja, annuleer deze taak", role: .destructive) {
                    appState.buddyCancelsAcceptedTask()
                    dismiss()
                }
                Button("Nee, ga door", role: .cancel) { }
            } message: {
                Text("De aanvraag wordt direct opnieuw aangeboden aan andere buddies in de buurt. \(task.elderlyName) krijgt hiervan bericht.")
            }
        }
    }

    // MARK: stages

    private var onTheWayContent: some View {
        ScrollView {
            VStack(spacing: BCSpacing.md) {
                taskHeader

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        Label("U bent onderweg", systemImage: "arrow.up.right.circle.fill")
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("Geschatte aankomst: \(task.assignedBuddyEtaMinutes ?? 12) minuten")
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                }

                Button {
                    showNavigation = true
                } label: {
                    miniMap.overlay(alignment: .bottomTrailing) {
                        Label("Navigeren", systemImage: "location.north.line.fill")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(.white)
                            .padding(.horizontal, BCSpacing.sm)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(BCColors.primary))
                            .padding(BCSpacing.sm)
                    }
                }
                .buttonStyle(.plain)

                BCCTAButton(title: "Navigeren naar het adres", icon: "location.north.line.fill", iconLeading: true) {
                    showNavigation = true
                }

                BCSecondaryButton(title: "Open route in Apple Kaarten", icon: "map.fill") {
                    openRouteInMaps(to: task)
                }
            }
            .padding(BCSpacing.lg)
        }
    }

    private var atDoorContent: some View {
        VStack(spacing: BCSpacing.md) {
            taskHeader
            BCCard {
                VStack(spacing: BCSpacing.md) {
                    Image(systemName: "location.fill.viewfinder")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(BCColors.primary)
                    Text("Klaar om in te checken?")
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Bevestig dat je bij \(task.elderlyName) bent aangekomen om het bezoek te starten.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        CheckInStepLabel(icon: "location.fill", text: "Aankomst bevestigen")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(BCSpacing.md)
            }
            Spacer()
        }
        .padding(BCSpacing.lg)
    }

    private var inProgressContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                taskHeader

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        Label("Checklist", systemImage: "checklist")
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.textPrimary)
                        ForEach($checklist) { $item in
                            Button {
                                item.done.toggle()
                            } label: {
                                HStack(spacing: BCSpacing.sm) {
                                    Image(systemName: item.done ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(item.done ? BCColors.success : BCColors.textTertiary)
                                    Text(item.text)
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                        .strikethrough(item.done, color: BCColors.textTertiary)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        Label("Bericht naar familie (optioneel)", systemImage: "text.bubble.fill")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textSecondary)
                        TextField("Bijvoorbeeld: Riet was vrolijk vandaag", text: $note, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .font(BCTypography.body)
                    }
                }
            }
            .padding(BCSpacing.lg)
        }
    }

    private var completingContent: some View {
        VStack(spacing: BCSpacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(BCColors.success)
            Text("Taak afronden")
                .font(BCTypography.title2)
                .foregroundStyle(BCColors.textPrimary)
            Text("Weet u zeker dat u deze taak wilt afronden?")
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BCSpacing.lg)
            Spacer()
        }
        .padding(BCSpacing.lg)
    }

    private var doneContent: some View {
        VStack(spacing: BCSpacing.md) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 64))
                .foregroundStyle(BCColors.accent)
            Text("Goed gedaan!")
                .font(BCTypography.title2)
                .foregroundStyle(BCColors.textPrimary)
            Text("Het bedrag wordt later via de app verrekend.")
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(BCSpacing.lg)
    }

    // MARK: shared

    private var taskHeader: some View {
        BCCard {
            HStack {
                Image(systemName: task.category.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(BCColors.primary))
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.category.displayName)
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Bij \(task.elderlyName) — \(task.elderlyAddress)")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                }
                Spacer()
                BCStatusPill(label: task.status.label, color: task.status.color)
            }
        }
    }

    private var miniMap: some View {
        let region = MKCoordinateRegion(center: task.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        return Map(initialPosition: .region(region)) {
            Marker(task.elderlyName, coordinate: task.coordinate)
                .tint(BCColors.primary)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous))
        .allowsHitTesting(false)
    }

    // MARK: bottom bar

    private var bottomBar: some View {
        VStack {
            Divider()
            switch stage {
            case .onTheWay:
                VStack(spacing: BCSpacing.sm) {
                    BCCTAButton(title: "Ik ben aangekomen", icon: "qrcode", iconLeading: true) {
                        stage = .atDoor
                    }
                    cancelTaskButton
                }
                .padding(BCSpacing.lg)
            case .atDoor:
                VStack(spacing: BCSpacing.sm) {
                    BCCTAButton(title: "Inchecken", icon: "qrcode.viewfinder", iconLeading: true) {
                        showCheckIn = true
                    }
                    cancelTaskButton
                }
                .padding(BCSpacing.lg)
            case .inProgress:
                BCCTAButton(title: "Taak afronden", icon: "checkmark", iconLeading: true) {
                    stage = .completing
                }
                .padding(BCSpacing.lg)
            case .completing:
                HStack(spacing: BCSpacing.sm) {
                    BCSecondaryButton(title: "Terug", icon: "chevron.left") {
                        stage = .inProgress
                    }
                    BCCTAButton(title: "Bevestig", icon: "checkmark", iconLeading: true) {
                        appState.buddyCompletes(notes: note)
                        stage = .done
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            dismiss()
                        }
                    }
                }
                .padding(BCSpacing.lg)
            case .done:
                BCPrimaryButton(title: "Sluiten", icon: "checkmark") {
                    dismiss()
                }
                .padding(BCSpacing.lg)
            }
        }
        .background(BCColors.background)
    }

    private var cancelTaskButton: some View {
        Button(role: .destructive) {
            showCancelConfirm = true
        } label: {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "xmark.circle")
                Text("Taak annuleren")
            }
            .font(BCTypography.bodyEmphasized)
            .foregroundStyle(BCColors.danger)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

private struct ChecklistItem: Identifiable {
    let id = UUID()
    let text: String
    var done: Bool
}

// MARK: - Helper: check-in stap label

private struct CheckInStepLabel: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BCColors.primary)
                .frame(width: 20)
            Text(text)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
        }
    }
}

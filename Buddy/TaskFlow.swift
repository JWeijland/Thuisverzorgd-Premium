import SwiftUI
import MapKit

// MARK: - Maps routing

/// Opent Apple Maps met een looproute naar het adres van de oudere.
func openRouteInMaps(to task: ServiceTask) {
    let placemark = MKPlacemark(coordinate: task.coordinate)
    let item = MKMapItem(placemark: placemark)
    item.name = "\(task.elderlyName) — \(task.elderlyAddress)"
    item.openInMaps(launchOptions: [
        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
    ])
}

// MARK: - Task detail sheet (tapped from map)

struct TaskDetailSheet: View {
    @Environment(AppState.self) private var appState
    let task: ServiceTask
    let onAccept: () -> Void

    private var canAccept: Bool {
        appState.effectiveBuddyLevel.rawValue >= task.requiredLevel.rawValue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack {
                    Image(systemName: task.category.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(task.requiredLevel.color))
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
                    if !appState.isCordaanBuddy {
                        BCLevelBadge(level: task.requiredLevel)
                    }
                    BCStatusPill(label: task.timing.displayName, color: BCColors.primary)
                    Spacer()
                }

                BCCard {
                    HStack {
                        if !appState.isCordaanBuddy {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Vergoeding")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textSecondary)
                                Text(task.priceFormatted)
                                    .font(BCTypography.title2)
                                    .foregroundStyle(BCColors.textPrimary)
                            }
                            Spacer()
                        }
                        VStack(alignment: appState.isCordaanBuddy ? .leading : .trailing, spacing: 2) {
                            Text("Afstand")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textSecondary)
                            Text("± 1,4 km")
                                .font(BCTypography.title3)
                                .foregroundStyle(BCColors.textPrimary)
                        }
                        if appState.isCordaanBuddy { Spacer() }
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

                if canAccept {
                    BCPrimaryButton(title: "Aannemen", icon: "checkmark.circle.fill") {
                        onAccept()
                    }
                } else {
                    VStack(spacing: BCSpacing.xs) {
                        BCPrimaryButton(title: "Niveau te laag", icon: "lock.fill") { }
                            .opacity(0.45)
                            .disabled(true)
                        Text("Deze taak vereist \(task.requiredLevel.title). Voltooi eerst de bijbehorende cursussen.")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }

                BCSecondaryButton(title: "Naar route bekijken", icon: "map.fill") {
                    openRouteInMaps(to: task)
                }
            }
            .padding(BCSpacing.lg)
        }
        .background(BCColors.background.ignoresSafeArea())
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

                miniMap

                BCSecondaryButton(title: "Open route in kaart", icon: "map.fill") {
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
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(BCColors.primary)
                    Text("Klaar om in te checken?")
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Maak een selfie, scan de QR-code op de telefoon van \(task.elderlyName) en bevestig je locatie.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        CheckInStepLabel(icon: "faceid", text: "Selfie (elk bezoek)")
                        CheckInStepLabel(icon: "qrcode.viewfinder", text: "QR-code scannen")
                        CheckInStepLabel(icon: "location.fill", text: "GPS-locatie bevestigen")
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
            Text(appState.isCordaanBuddy
                 ? "Het bezoek is geregistreerd bij de zorginstelling."
                 : "De vergoeding wordt binnen 24 uur uitbetaald.")
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
                    .background(Circle().fill(task.requiredLevel.color))
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
                .tint(task.requiredLevel.color)
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
                BCPrimaryButton(title: "Ik ben aangekomen", icon: "qrcode") {
                    stage = .atDoor
                }
                .padding(BCSpacing.lg)
            case .atDoor:
                BCPrimaryButton(title: "Start check-in", icon: "qrcode.viewfinder") {
                    showCheckIn = true
                }
                .padding(BCSpacing.lg)
            case .inProgress:
                BCPrimaryButton(title: "Taak afronden", icon: "checkmark.circle.fill") {
                    stage = .completing
                }
                .padding(BCSpacing.lg)
            case .completing:
                HStack(spacing: BCSpacing.sm) {
                    BCSecondaryButton(title: "Terug", icon: "chevron.left") {
                        stage = .inProgress
                    }
                    BCPrimaryButton(title: "Bevestig", icon: "checkmark") {
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

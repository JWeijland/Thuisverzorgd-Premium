import SwiftUI
import MapKit

struct BuddyMapView: View {
    @Environment(AppState.self) private var appState
    @State private var cameraPosition: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(
            center: MockData.amsterdamCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        ))
    )
    @State private var selectedTask: ServiceTask? = nil
    @State private var maxLevelFilter: Int = 4   // standaard: alle niveaus tonen
    @State private var showActiveTask = false

    var visibleTasks: [ServiceTask] {
        guard appState.isAvailableNow else { return [] }
        return appState.openTasks.filter { $0.requiredLevel.rawValue <= maxLevelFilter }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: Binding(
                get: { selectedTask?.id },
                set: { id in
                    if let id, let task = appState.openTasks.first(where: { $0.id == id }) {
                        selectedTask = task
                    } else {
                        selectedTask = nil
                    }
                })) {
                ForEach(visibleTasks) { task in
                    Annotation(task.category.displayName, coordinate: task.coordinate) {
                        MapPin(task: task, isSelected: selectedTask?.id == task.id)
                    }
                    .tag(task.id)
                }
                UserAnnotation()
            }
            .mapControlVisibility(.hidden)
            .ignoresSafeArea()

            VStack(spacing: BCSpacing.sm) {
                topBar
                filterStrip
                if !appState.isAvailableNow {
                    offlineBanner
                }
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.top, BCSpacing.sm)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task) {
                appState.buddyAcceptsTask(task)
                selectedTask = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showActiveTask) {
            if let task = appState.activeTaskForBuddy {
                TaskInProgressView(task: task)
            }
        }
        .onChange(of: appState.activeTaskForBuddy) { _, newValue in
            if newValue != nil { showActiveTask = true }
        }
    }

    private var topBar: some View {
        HStack(spacing: BCSpacing.sm) {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "house.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BCColors.accent)
                Text("Thuisverzorgd")
                    .font(BCFont.heading(15, .bold))
                    .foregroundStyle(BCColors.navy900)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: BCSpacing.xs)
            availabilityPill
            BCStatusPill(label: "\(visibleTasks.count) open", color: BCColors.primary)
        }
        .padding(.horizontal, BCSpacing.md)
        .padding(.vertical, BCSpacing.sm)
        .background(
            Capsule(style: .continuous).fill(BCColors.surface)
        )
        .bcSoftShadow(.raised)
    }

    private var availabilityPill: some View {
        Button {
            appState.isAvailableNow.toggle()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.isAvailableNow ? BCColors.navy900 : BCColors.textTertiary)
                    .frame(width: 8, height: 8)
                Text(appState.isAvailableNow ? "Beschikbaar" : "Uit")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(appState.isAvailableNow ? BCColors.navy900 : BCColors.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous).fill(
                    appState.isAvailableNow
                        ? BCColors.accent
                        : BCColors.surfaceMuted
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var offlineBanner: some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BCColors.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Je staat op niet-beschikbaar")
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Zet \u{201C}Aan\u{201D} om hulpaanvragen in de buurt te ontvangen")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
            }
            Spacer()
            Button("Aanzetten") {
                appState.isAvailableNow = true
            }
            .font(BCTypography.captionEmphasized)
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(BCColors.accent))
            .foregroundStyle(BCColors.navy900)
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.surface)
        )
        .bcSoftShadow(.raised)
    }

    private var filterStrip: some View {
        HStack(spacing: BCSpacing.xs) {
            // "Alle" toont alles; de niveau-chips zijn cumulatief ("t/m").
            filterChip(label: "Alle", isOn: maxLevelFilter >= 4) { maxLevelFilter = 4 }
            ForEach([0, 1, 2, 3], id: \.self) { lvl in
                filterChip(label: "t/m \(lvl)", isOn: maxLevelFilter == lvl) { maxLevelFilter = lvl }
            }
        }
        .padding(BCSpacing.xs)
        .background(
            Capsule().fill(BCColors.background.opacity(0.95))
        )
    }

    private func filterChip(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(isOn ? .white : BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.sm)
                .padding(.vertical, BCSpacing.sm)
                .background(Capsule().fill(isOn ? BCColors.primary : BCColors.surface))
                .overlay(Capsule().stroke(BCColors.border, lineWidth: isOn ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}

private struct MapPin: View {
    let task: ServiceTask
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(task.requiredLevel.color)
                    .frame(width: isSelected ? 52 : 44, height: isSelected ? 52 : 44)
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                Image(systemName: task.category.icon)
                    .font(.system(size: isSelected ? 22 : 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Triangle()
                .fill(task.requiredLevel.color)
                .frame(width: 12, height: 8)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    BuddyMapView().environment(AppState())
}

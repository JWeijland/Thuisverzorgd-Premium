import SwiftUI

struct CoursesView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedCourse: Course? = nil
    @State private var celebrationLevel: ServiceLevel? = nil
    @State private var celebrationParticles: [CelebrationParticle] = []
    @State private var prevCompletedLevels: Set<ServiceLevel> = []

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                BCNavBar(title: "Cursussen", subtitle: "Groei naar het volgende niveau")

                ScrollView {
                    VStack(spacing: BCSpacing.md) {
                        levelHeader
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.md)

                        ForEach(ServiceLevel.allCases.prefix(4)) { level in
                            let coursesForLevel = appliedCourses.filter { $0.level == level }
                            if !coursesForLevel.isEmpty {
                                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                                    HStack {
                                        BCLevelBadge(level: level)
                                        Text(level.title)
                                            .font(BCTypography.headline)
                                            .foregroundStyle(BCColors.textPrimary)
                                        Spacer()
                                        if completedLevels.contains(level) {
                                            Label("Behaald!", systemImage: "checkmark.seal.fill")
                                                .font(BCTypography.captionEmphasized)
                                                .foregroundStyle(BCColors.success)
                                                .transition(.scale.combined(with: .opacity))
                                        } else if appState.isDemoMode && !completedLevels.contains(level) {
                                            Button {
                                                appState.debugCompleteLevel(level)
                                            } label: {
                                                Label("Demo", systemImage: "bolt.fill")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(BCColors.accent)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Capsule().fill(BCColors.accent.opacity(0.12)))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    Text(level.requirementText)
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textTertiary)

                                    VStack(spacing: BCSpacing.sm) {
                                        ForEach(coursesForLevel) { course in
                                            CourseRow(course: course) {
                                                if course.unlocked {
                                                    selectedCourse = course
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, BCSpacing.lg)
                                .padding(.top, BCSpacing.sm)
                            }
                        }
                        Spacer().frame(height: BCSpacing.xl)
                    }
                }
            }
            .background(BCColors.background.ignoresSafeArea())

            if let lvl = celebrationLevel {
                ConfettiOverlay(particles: celebrationParticles)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    VStack(spacing: BCSpacing.sm) {
                        Text("🎉")
                            .font(.system(size: 48))
                        Text("Niveau \(lvl.rawValue) behaald!")
                            .font(BCTypography.titleEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                        Text(lvl.celebrationMessage)
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, BCSpacing.xl)
                    }
                    .padding(BCSpacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                            .fill(BCColors.surface)
                            .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
                    )
                    .padding(.horizontal, BCSpacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    Spacer().frame(height: BCSpacing.xxl)
                }
            }
        }
        .sheet(item: $selectedCourse) { course in
            CourseDetailView(course: course)
        }
        .onChange(of: completedLevels) { _, nowDone in
            let newlyDone = nowDone.subtracting(prevCompletedLevels)
            prevCompletedLevels = nowDone
            if let level = newlyDone.sorted(by: { $0.rawValue < $1.rawValue }).first {
                triggerCelebration(for: level)
            }
        }
        .onAppear {
            prevCompletedLevels = completedLevels
        }
    }

    private var completedLevels: Set<ServiceLevel> {
        Set(ServiceLevel.allCases.prefix(4).filter { level in
            let courses = appliedCourses.filter { $0.level == level }
            return !courses.isEmpty && courses.allSatisfy { $0.progressPercent == 100 }
        })
    }

    private func triggerCelebration(for level: ServiceLevel) {
        celebrationParticles = (0..<60).map { _ in CelebrationParticle() }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            celebrationLevel = level
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                celebrationLevel = nil
            }
        }
    }

    private var appliedCourses: [Course] {
        // First pass: apply completion data
        var built = MockData.courses.map { course in
            let done = appState.completedModules[course.id] ?? []
            var c = course
            for i in c.modules.indices {
                c.modules[i].isCompleted = done.contains(c.modules[i].id)
            }
            let total = c.modules.count
            let completed = c.modules.filter(\.isCompleted).count
            c.progressPercent = total > 0 ? Int(Double(completed) / Double(total) * 100) : 0
            return c
        }
        // Second pass: unlock a level when all courses of the previous level are done
        for level in ServiceLevel.allCases {
            guard level.rawValue > 0,
                  let prev = ServiceLevel(rawValue: level.rawValue - 1) else { continue }
            let prevDone = built.filter { $0.level == prev }.allSatisfy { $0.progressPercent == 100 }
            if prevDone {
                for i in built.indices where built[i].level == level {
                    built[i].unlocked = true
                }
            }
        }
        return built
    }

    /// Het eerstvolgende niveau (indien aanwezig) en de voortgang van de cursussen daarvan.
    private var nextLevel: ServiceLevel? {
        ServiceLevel(rawValue: appState.buddyUser.level.rawValue + 1)
            .flatMap { lvl in lvl.rawValue <= 3 ? lvl : nil }
    }

    private var nextLevelProgress: Double {
        guard let next = nextLevel else { return 1 }
        let courses = appliedCourses.filter { $0.level == next }
        guard !courses.isEmpty else { return 0 }
        let avg = courses.reduce(0) { $0 + $1.progressPercent } / courses.count
        return Double(avg) / 100
    }

    private var levelHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [BCColors.navy900, BCColors.navy700],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.12)).frame(width: 52, height: 52)
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(BCColors.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Jouw niveau")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(.white.opacity(0.75))
                        Text("\(appState.buddyUser.level.title) · niveau \(appState.buddyUser.level.rawValue)")
                            .font(BCTypography.title3)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }

                Text(appState.buddyUser.level.summary)
                    .font(BCTypography.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)

                if let next = nextLevel {
                    BCProgressBar(value: nextLevelProgress, color: BCColors.accent)
                    Text("Op weg naar niveau \(next.rawValue) — \(next.title)")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(BCSpacing.lg)
        }
        .bcSoftShadow(.raised)
    }
}

private struct CourseRow: View {
    let course: Course
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BCCard {
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    HStack {
                        Text(course.title)
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                        Spacer()
                        if !course.unlocked {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(BCColors.textTertiary)
                        } else if course.progressPercent == 100 {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(BCColors.success)
                        }
                    }
                    Text(course.summary)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .lineLimit(2)
                    HStack(spacing: BCSpacing.sm) {
                        Label("\(course.modulesCount) modules", systemImage: "list.bullet")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                        Label("\(course.durationMinutes) min", systemImage: "clock")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                        Spacer()
                        if course.requiresPhysicalCertification {
                            Label("Praktijktoets", systemImage: "building.2.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(BCColors.level2)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(BCColors.level2.opacity(0.1)))
                        }
                    }
                    if course.unlocked && course.progressPercent > 0 && course.progressPercent < 100 {
                        BCProgressBar(value: Double(course.progressPercent) / 100)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(course.unlocked ? 1.0 : 0.55)
    }
}

// MARK: - Course Detail View

struct CourseDetailView: View {
    @State private var courseState: Course
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var activeModule: CourseModuleData? = nil
    @State private var showCertificate: Bool = false

    init(course: Course) {
        _courseState = State(initialValue: course)
    }

    private var firstIncompleteModule: CourseModuleData? {
        courseState.modules.first(where: { !$0.isCompleted })
    }

    private var progressPercent: Int {
        let done = courseState.modules.filter(\.isCompleted).count
        let total = courseState.modules.count
        guard total > 0 else { return 0 }
        return Int(Double(done) / Double(total) * 100)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    HStack {
                        BCLevelBadge(level: courseState.level)
                        if progressPercent == 100 {
                            BCStatusPill(label: "Voltooid", color: BCColors.success)
                        } else if progressPercent > 0 {
                            BCStatusPill(label: "\(progressPercent)% voltooid", color: BCColors.primary)
                        }
                        Spacer()
                    }

                    Text(courseState.title)
                        .font(BCTypography.title)
                        .foregroundStyle(BCColors.textPrimary)

                    Text(courseState.summary)
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)

                    HStack(spacing: BCSpacing.md) {
                        Label("\(courseState.durationMinutes) min", systemImage: "clock.fill")
                        Label("\(courseState.modulesCount) modules", systemImage: "list.bullet")
                    }
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)

                    if progressPercent > 0 && progressPercent < 100 {
                        BCProgressBar(value: Double(progressPercent) / 100, label: "Voortgang", color: BCColors.primary)
                    }

                    if courseState.requiresPhysicalCertification {
                        physicalCertBanner
                    }

                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Text("Modules")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                            ForEach(Array(courseState.modules.enumerated()), id: \.element.id) { index, mod in
                                let isAccessible = mod.isCompleted || mod.id == firstIncompleteModule?.id
                                Button {
                                    if isAccessible { activeModule = mod }
                                } label: {
                                    HStack(spacing: BCSpacing.sm) {
                                        ZStack {
                                            Circle()
                                                .fill(mod.isCompleted ? BCColors.success : (isAccessible ? BCColors.primary.opacity(0.12) : BCColors.border))
                                                .frame(width: 32, height: 32)
                                            if mod.isCompleted {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(.white)
                                            } else {
                                                Image(systemName: moduleIcon(mod.type))
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(isAccessible ? BCColors.primary : BCColors.textSecondary)
                                            }
                                        }
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(mod.title)
                                                .font(BCTypography.body)
                                                .foregroundStyle(mod.isCompleted ? BCColors.textSecondary : BCColors.textPrimary)
                                                .strikethrough(mod.isCompleted, color: BCColors.textTertiary)
                                            Text("\(mod.durationMinutes) min")
                                                .font(BCTypography.caption)
                                                .foregroundStyle(BCColors.textTertiary)
                                        }
                                        Spacer()
                                        if mod.id == firstIncompleteModule?.id {
                                            BCStatusPill(label: "Volgende", color: BCColors.primary)
                                        } else if !isAccessible {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(BCColors.textTertiary)
                                        }
                                    }
                                    .padding(.vertical, BCSpacing.xs)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if courseState.unlocked {
                        if progressPercent == 100 {
                            BCSecondaryButton(title: "Bekijk certificaat", icon: "rosette") {
                                showCertificate = true
                            }
                        } else {
                            BCCTAButton(
                                title: progressPercent > 0 ? "Doorgaan" : "Start cursus",
                                icon: progressPercent > 0 ? "arrow.right" : "play.fill",
                                iconLeading: true
                            ) {
                                activeModule = firstIncompleteModule
                            }
                        }
                    } else {
                        BCSecondaryButton(title: "Vorig niveau eerst afronden", icon: "lock.fill") { }
                    }
                }
                .padding(BCSpacing.lg)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Cursus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
            .sheet(item: $activeModule) { mod in
                CourseModuleView(module: mod, courseTitle: courseState.title) {
                    handleModuleComplete(mod)
                }
            }
            .sheet(isPresented: $showCertificate) {
                CertificateView(level: courseState.level, buddyName: appState.buddyUser.fullName)
            }
        }
    }

    // MARK: - Module completion & auto-advance

    private func handleModuleComplete(_ mod: CourseModuleData) {
        if let idx = courseState.modules.firstIndex(where: { $0.id == mod.id }) {
            courseState.modules[idx].isCompleted = true
        }
        appState.recordModuleComplete(courseId: courseState.id, moduleId: mod.id)
        activeModule = nil

        let next = courseState.modules.first(where: { !$0.isCompleted })

        if next == nil {
            // All modules done → certificate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showCertificate = true
            }
        } else if mod.type != .quiz {
            // Auto-advance to next module
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                activeModule = next
            }
        }
    }

    private var physicalCertBanner: some View {
        HStack(alignment: .top, spacing: BCSpacing.md) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(BCColors.level2)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: BCSpacing.xs) {
                Text("Praktijktoets vereist")
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.level2)
                Text("Na het afronden van de e-learning moet je een praktijktoets afleggen bij een erkende Thuisverzorgd-locatie. Locaties worden bekendgemaakt zodra Niveau 2 beschikbaar komt. Na de toets ontvang je het officiële niveau-certificaat.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
            }
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                .fill(BCColors.level2.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .stroke(BCColors.level2.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func moduleIcon(_ type: ModuleType) -> String {
        switch type {
        case .video:   return "play.fill"
        case .quiz:    return "checkmark.circle"
        case .reading: return "book.fill"
        }
    }
}

// MARK: - Confetti

struct CelebrationParticle: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: 0...1)
    let delay: Double = Double.random(in: 0...0.6)
    let duration: Double = Double.random(in: 1.8...3.0)
    let size: CGFloat = CGFloat.random(in: 7...14)
    let rotation: Double = Double.random(in: 0...360)
    let rotationSpeed: Double = Double.random(in: 180...540)
    let color: Color = [
        BCColors.primary, BCColors.accent, BCColors.success,
        BCColors.level1, BCColors.level2, Color.yellow, Color.pink
    ].randomElement()!
    let shape: Int = Int.random(in: 0...2)
}

private struct ConfettiOverlay: View {
    let particles: [CelebrationParticle]

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                ConfettiPiece(particle: p, height: geo.size.height)
                    .position(x: p.x * geo.size.width, y: -20)
            }
        }
    }
}

private struct ConfettiPiece: View {
    let particle: CelebrationParticle
    let height: CGFloat
    @State private var offset: CGFloat = 0
    @State private var spin: Double = 0

    var body: some View {
        Group {
            if particle.shape == 0 {
                Circle().fill(particle.color).frame(width: particle.size, height: particle.size)
            } else if particle.shape == 1 {
                Rectangle().fill(particle.color).frame(width: particle.size, height: particle.size * 0.6)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(particle.color).frame(width: particle.size * 0.5, height: particle.size)
            }
        }
        .rotationEffect(.degrees(particle.rotation + spin))
        .offset(y: offset)
        .onAppear {
            withAnimation(
                .linear(duration: particle.duration)
                .delay(particle.delay)
            ) {
                offset = height + 60
                spin = particle.rotationSpeed
            }
        }
    }
}

#Preview {
    CoursesView().environment(AppState())
}

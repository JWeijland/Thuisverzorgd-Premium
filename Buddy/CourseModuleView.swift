import SwiftUI

struct CourseModuleView: View {
    let module: CourseModuleData
    let courseTitle: String
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch module.type {
                case .video:  VideoModuleView(module: module, onComplete: { onComplete(); dismiss() })
                case .reading: ReadingModuleView(module: module, onComplete: { onComplete(); dismiss() })
                case .quiz:   QuizModuleView(module: module, courseTitle: courseTitle, onPass: { onComplete(); dismiss() })
                }
            }
            .navigationTitle(module.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
        }
    }
}

// MARK: - Video module

private struct VideoModuleView: View {
    let module: CourseModuleData
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: BCSpacing.lg) {
                    ZStack {
                        RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                            .fill(BCColors.primary.opacity(0.92))
                            .frame(height: 220)
                        VStack(spacing: BCSpacing.md) {
                            Image(systemName: module.illustrationSymbol)
                                .font(.system(size: 52, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(module.durationMinutes) min")
                                .font(BCTypography.captionEmphasized)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Label("Over deze video", systemImage: "info.circle.fill")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                            Text(module.videoDescription)
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                                .lineSpacing(5)
                            // TODO[real-content]: Upload video for this module
                            Label("Video wordt binnenkort toegevoegd", systemImage: "clock.fill")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textTertiary)
                                .padding(.top, BCSpacing.xs)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                }
                .padding(.vertical, BCSpacing.lg)
            }

            Divider()
            BCCTAButton(title: "Markeer als bekeken", icon: "checkmark", iconLeading: true, action: onComplete)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.md)
        }
    }
}

// MARK: - Reading module

private struct ReadingModuleView: View {
    let module: CourseModuleData
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.xl) {
                    BCCard {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "clock")
                                .foregroundStyle(BCColors.textSecondary)
                            Text("Leestijd: ca. \(module.durationMinutes) minuten")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    ForEach(module.readingSections) { section in
                        VStack(alignment: .leading, spacing: BCSpacing.md) {
                            BCIllustrationCard(
                                symbol: section.symbol,
                                color: BCColors.primary,
                                caption: section.heading
                            )
                            .frame(height: 160)
                            .padding(.horizontal, BCSpacing.lg)

                            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                                Text(section.heading)
                                    .font(BCTypography.title3)
                                    .foregroundStyle(BCColors.textPrimary)

                                ForEach(Array(section.body.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, para in
                                    Text(para)
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                        .lineSpacing(5)
                                }
                            }
                            .padding(.horizontal, BCSpacing.lg)
                        }
                    }

                    Color.clear.frame(height: BCSpacing.md)
                }
                .padding(.vertical, BCSpacing.lg)
            }

            Divider()
            BCCTAButton(title: "Klaar met lezen", icon: "checkmark", iconLeading: true, action: onComplete)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.md)
        }
    }
}

// MARK: - Quiz module

private struct QuizModuleView: View {
    let module: CourseModuleData
    let courseTitle: String
    let onPass: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var selectedAnswer: Int? = nil
    @State private var confirmedAnswer: Int? = nil
    @State private var answers: [Int] = []
    @State private var showResult: Bool = false

    private var questions: [QuizQuestionData] { module.quizQuestions }
    private var score: Int { zip(answers, questions).filter { $0.0 == $0.1.correctIndex }.count }
    private var passed: Bool { Double(score) / Double(questions.count) >= 0.8 }

    var body: some View {
        if showResult { resultView } else { questionView }
    }

    private var questionView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    BCProgressBar(
                        value: Double(currentIndex) / Double(questions.count),
                        label: "Vraag \(currentIndex + 1) van \(questions.count)"
                    )

                    BCIllustrationCard(
                        symbol: module.illustrationSymbol,
                        color: BCColors.primary,
                        caption: courseTitle
                    )
                    .frame(height: 120)

                    Text(questions[currentIndex].question)
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                        .padding(.top, BCSpacing.xs)

                    VStack(spacing: BCSpacing.sm) {
                        ForEach(Array(questions[currentIndex].options.enumerated()), id: \.offset) { idx, option in
                            let isSelected = selectedAnswer == idx
                            let isConfirmed = confirmedAnswer != nil
                            let isCorrect = idx == questions[currentIndex].correctIndex
                            let isWrong = isConfirmed && isSelected && !isCorrect

                            Button {
                                if confirmedAnswer == nil { selectedAnswer = idx }
                            } label: {
                                HStack(spacing: BCSpacing.md) {
                                    ZStack {
                                        Circle()
                                            .stroke(answerBorder(idx: idx, isConfirmed: isConfirmed, isCorrect: isCorrect), lineWidth: 2)
                                            .frame(width: 28, height: 28)
                                        if isConfirmed && isCorrect {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(BCColors.success)
                                        } else if isWrong {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(BCColors.danger)
                                        } else if isSelected {
                                            Circle().fill(BCColors.primary).frame(width: 16, height: 16)
                                        }
                                    }
                                    Text(option)
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .padding(BCSpacing.md)
                                .frame(minHeight: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                        .fill(answerBackground(idx: idx, isConfirmed: isConfirmed, isCorrect: isCorrect))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                        .stroke(answerBorder(idx: idx, isConfirmed: isConfirmed, isCorrect: isCorrect), lineWidth: isSelected || (isConfirmed && isCorrect) ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(confirmedAnswer != nil && !isCorrect && idx != confirmedAnswer)
                            .accessibilityLabel("Antwoordoptie \(idx + 1): \(option)")
                        }
                    }

                    if confirmedAnswer != nil {
                        BCCard {
                            HStack(alignment: .top, spacing: BCSpacing.sm) {
                                Image(systemName: confirmedAnswer == questions[currentIndex].correctIndex ? "checkmark.circle.fill" : "info.circle.fill")
                                    .foregroundStyle(confirmedAnswer == questions[currentIndex].correctIndex ? BCColors.success : BCColors.warning)
                                Text(questions[currentIndex].explanation)
                                    .font(BCTypography.body)
                                    .foregroundStyle(BCColors.textPrimary)
                                    .lineSpacing(4)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(BCSpacing.lg)
                .animation(.easeInOut(duration: 0.2), value: confirmedAnswer)
            }

            Divider()

            if confirmedAnswer == nil {
                BCCTAButton(title: "Bevestig antwoord", icon: "checkmark", iconLeading: true) {
                    if selectedAnswer != nil { confirmedAnswer = selectedAnswer }
                }
                .opacity(selectedAnswer != nil ? 1.0 : 0.4)
                .disabled(selectedAnswer == nil)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.md)
            } else {
                BCCTAButton(
                    title: currentIndex < questions.count - 1 ? "Volgende vraag" : "Bekijk resultaat",
                    icon: currentIndex < questions.count - 1 ? "chevron.right" : "checkmark.seal"
                ) {
                    answers.append(confirmedAnswer!)
                    selectedAnswer = nil
                    confirmedAnswer = nil
                    if currentIndex < questions.count - 1 {
                        currentIndex += 1
                    } else {
                        showResult = true
                    }
                }
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.md)
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()

            Image(systemName: passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(passed ? BCColors.success : BCColors.danger)

            VStack(spacing: BCSpacing.sm) {
                Text(passed ? "Geslaagd!" : "Niet geslaagd")
                    .font(BCTypography.title2)
                    .foregroundStyle(BCColors.textPrimary)
                Text("\(score) van de \(questions.count) vragen goed (\(Int(Double(score) / Double(questions.count) * 100))%)")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                if !passed {
                    Text("U heeft minimaal 80% nodig om te slagen. Lees de uitleg terug en probeer het opnieuw.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BCSpacing.lg)
                }
            }

            Spacer()

            VStack(spacing: BCSpacing.sm) {
                if passed {
                    BCCTAButton(title: "Certificaat ophalen", icon: "rosette", iconLeading: true, action: onPass)
                        .padding(.horizontal, BCSpacing.lg)
                } else {
                    BCPrimaryButton(title: "Opnieuw proberen", icon: "arrow.counterclockwise") {
                        currentIndex = 0; answers = []; selectedAnswer = nil
                        confirmedAnswer = nil; showResult = false
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    BCSecondaryButton(title: "Sluiten", icon: "xmark") { dismiss() }
                        .padding(.horizontal, BCSpacing.lg)
                }
            }
            .padding(.bottom, BCSpacing.xl)
        }
    }

    private func answerBackground(idx: Int, isConfirmed: Bool, isCorrect: Bool) -> Color {
        guard isConfirmed else {
            return selectedAnswer == idx ? BCColors.primaryMuted : BCColors.surface
        }
        if isCorrect { return BCColors.success.opacity(0.10) }
        if idx == confirmedAnswer { return BCColors.danger.opacity(0.10) }
        return BCColors.surface
    }

    private func answerBorder(idx: Int, isConfirmed: Bool, isCorrect: Bool) -> Color {
        guard isConfirmed else {
            return selectedAnswer == idx ? BCColors.primary : BCColors.border
        }
        if isCorrect { return BCColors.success }
        if idx == confirmedAnswer { return BCColors.danger }
        return BCColors.border
    }
}

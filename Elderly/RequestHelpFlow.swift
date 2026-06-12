import SwiftUI

struct RequestHelpFlow: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    /// Indien gezet vraagt een familielid hulp aan namens deze oudere.
    /// Indien nil vraagt de oudere zelf hulp aan.
    var onBehalfOf: ElderlyUser? = nil

    private var targetElderly: ElderlyUser { onBehalfOf ?? appState.elderlyUser }

    @State private var step: Int = 0
    @State private var descriptionText: String = ""
    @State private var selectedCategory: TaskCategory? = nil
    @State private var otherDescription: String = ""
    @State private var selectedTiming: TaskTiming? = nil
    @State private var note: String = ""
    @State private var showingConfirmation = false
    @State private var customDate: Date = Date().addingTimeInterval(3600)
    @State private var useCustomDate: Bool = false
    @State private var showVoiceInput: Bool = false
    // Betaalde extra's
    @State private var selectedExtras: Set<RequestExtra> = []
    @State private var showCheckout: Bool = false
    // Recurring
    @State private var isRecurring: Bool = false
    @State private var recurringFrequency: RecurringFrequency = .daily
    @State private var recurringEndDate: Date = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
    @State private var useCustomEndDate: Bool = false
    @Environment(\.largeTextEnabled) private var largeText
    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    private var recurringSchedule: RecurringSchedule? {
        isRecurring ? RecurringSchedule(frequency: recurringFrequency, endDate: recurringEndDate) : nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                Group {
                    switch step {
                    case 0: categoryStep
                    case 1: timingStep
                    case 2: confirmStep
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomBar
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Hulp vragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") { dismiss() }
                        .tint(BCColors.primary)
                }
            }
            .sheet(isPresented: $showVoiceInput) {
                VoiceTaskInputView { spokenText in
                    applySpokenTranscript(spokenText)
                }
            }
            .sheet(isPresented: $showCheckout) {
                ExtrasCheckoutSheet(
                    extras: sortedSelectedExtras,
                    basePriceCents: selectedCategory?.suggestedPriceCents ?? 0
                ) { purchase in
                    showCheckout = false
                    submit(purchase: purchase)
                }
                .environment(appState)
            }
        }
    }

    private var sortedSelectedExtras: [RequestExtra] {
        RequestExtra.allCases.filter { selectedExtras.contains($0) }
    }

    private func applySpokenTranscript(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        descriptionText = trimmed
        if let match = recognizeCategory(from: trimmed) {
            selectedCategory = match
            if match == .other {
                otherDescription = trimmed
            }
        } else {
            // Geen categorie herkend → val terug op 'Anders' met transcript
            selectedCategory = .other
            otherDescription = trimmed
        }
    }

    private var progressBar: some View {
        HStack(spacing: BCSpacing.xs) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i <= step ? BCColors.accent : BCColors.border)
                    .frame(height: 6)
            }
        }
    }

    private var voiceInputCallout: some View {
        Button {
            showVoiceInput = true
        } label: {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(BCColors.navy900)
                    Image(systemName: "mic.fill")
                        .font(.system(size: largeText ? 34 : 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: et.iconBoxSize, height: et.iconBoxSize)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Spreek het in")
                        .font(et.button)
                        .foregroundStyle(BCColors.navy900)
                    Text("Tik en vertel rustig wat u nodig heeft")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: BCSpacing.sm)

                ZStack {
                    Circle().fill(BCColors.accent)
                    Image(systemName: "arrow.right")
                        .font(.system(size: largeText ? 24 : 20, weight: .bold))
                        .foregroundStyle(BCColors.navy900)
                }
                .frame(width: largeText ? 64 : 56, height: largeText ? 64 : 56)
            }
            .padding(largeText ? BCSpacing.lg : BCSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.raised)
        }
        .buttonStyle(.plain)
    }

    // STEP 0 — categorie
    private var categoryStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                Text("Waar heeft u hulp bij nodig?")
                    .font(et.heading)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                voiceInputCallout
                    .padding(.horizontal, BCSpacing.lg)

                HStack(spacing: BCSpacing.sm) {
                    Rectangle().fill(BCColors.border).frame(height: 1)
                    Text("of kies hieronder")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                    Rectangle().fill(BCColors.border).frame(height: 1)
                }
                .padding(.horizontal, BCSpacing.lg)

                // Smart description field
                VStack(alignment: .leading, spacing: BCSpacing.xs) {
                    Text("Beschrijf in uw eigen woorden (optioneel)")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .padding(.horizontal, BCSpacing.lg)
                    TextField("Bijv. \"ik kan niet naar de winkel lopen\"", text: $descriptionText, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                        .font(et.body)
                        .padding(BCSpacing.md)
                        .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                        .bcSoftShadow(.subtle)
                        .padding(.horizontal, BCSpacing.lg)
                        .onChange(of: descriptionText) { _, text in
                            if let match = recognizeCategory(from: text) {
                                selectedCategory = match
                            }
                        }
                    if let match = recognizeCategory(from: descriptionText), !descriptionText.isEmpty {
                        HStack(spacing: BCSpacing.xs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Herkend als: \(match.displayName)")
                                .font(BCTypography.captionEmphasized)
                        }
                        .foregroundStyle(BCColors.green700)
                        .padding(.horizontal, BCSpacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: descriptionText)

                let columns = largeText
                    ? [GridItem(.flexible())]
                    : [GridItem(.flexible(), spacing: BCSpacing.sm), GridItem(.flexible(), spacing: BCSpacing.sm)]
                LazyVGrid(columns: columns, spacing: BCSpacing.sm) {
                    ForEach(TaskCategory.allCases) { category in
                        CategoryTile(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                if selectedCategory == .other {
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        Text("Beschrijf wat er nodig is")
                            .font(et.caption)
                            .foregroundStyle(BCColors.textSecondary)
                            .padding(.horizontal, BCSpacing.lg)
                        TextField("Bijv. \"helpen met douchen en aankleden\"", text: $otherDescription, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .font(et.body)
                            .padding(BCSpacing.md)
                            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(
                                otherDescription.isEmpty ? Color.clear : BCColors.accent, lineWidth: otherDescription.isEmpty ? 0 : 1.5
                            ))
                            .bcSoftShadow(.subtle)
                            .padding(.horizontal, BCSpacing.lg)
                    }
                    .animation(.easeInOut(duration: 0.2), value: otherDescription)
                } else if let cat = selectedCategory {
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.xs) {
                            HStack {
                                Text(cat.displayName)
                                    .font(BCTypography.headline)
                                    .foregroundStyle(BCColors.textPrimary)
                                Spacer()
                            }
                            Text(cat.description)
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                }
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    // STEP 1 — tijd
    private var timingStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                Text("Wanneer wilt u hulp?")
                    .font(et.heading)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                // Eenmalig / Periodiek toggle
                Picker("", selection: $isRecurring) {
                    Text("Eenmalig").tag(false)
                    Text("Periodiek").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, BCSpacing.lg)
                .onChange(of: isRecurring) { _, _ in
                    selectedTiming = nil
                    useCustomDate = false
                }

                // Timing tiles
                VStack(spacing: BCSpacing.sm) {
                    if !isRecurring {
                        TimingTile(title: "Zo snel mogelijk", subtitle: "Een buddy in de buurt komt eraan",
                                   icon: "bolt.fill", isSelected: selectedTiming == .now && !useCustomDate) {
                            useCustomDate = false; selectedTiming = .now
                        }
                    }
                    TimingTile(title: "Vandaag om 16:00", subtitle: "Plan voor vanmiddag",
                               icon: "clock.fill", isSelected: selectedTiming == .today(hour: 16) && !useCustomDate) {
                        useCustomDate = false; selectedTiming = .today(hour: 16)
                    }
                    TimingTile(title: "Morgen om 10:00", subtitle: "Plan voor morgenochtend",
                               icon: "sunrise.fill", isSelected: selectedTiming == .scheduled(date: tomorrowAt10) && !useCustomDate) {
                        useCustomDate = false; selectedTiming = .scheduled(date: tomorrowAt10)
                    }
                    TimingTile(title: "Zelf kiezen", subtitle: "Kies een datum en tijd",
                               icon: "calendar.badge.clock", isSelected: useCustomDate) {
                        useCustomDate = true; selectedTiming = .scheduled(date: customDate)
                    }
                    if useCustomDate {
                        DatePicker("", selection: $customDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(BCColors.accent)
                            .padding(BCSpacing.md)
                            .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                            .bcSoftShadow(.card)
                            .onChange(of: customDate) { _, d in selectedTiming = .scheduled(date: d) }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                // Periodieke opties
                if isRecurring {
                    recurringSection
                }

                // Opmerking
                VStack(alignment: .leading, spacing: BCSpacing.xs) {
                    Text("Opmerking voor de buddy (optioneel)")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                    TextField("Bijv. bel twee keer aan", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .font(et.body)
                        .padding(BCSpacing.md)
                        .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                        .bcSoftShadow(.subtle)
                }
                .padding(.horizontal, BCSpacing.lg)
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Hoe vaak?")
                .font(et.body)
                .foregroundStyle(BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.lg)

            VStack(spacing: BCSpacing.sm) {
                ForEach(RecurringFrequency.allCases) { freq in
                    TimingTile(title: freq.rawValue, subtitle: "", icon: freq.icon,
                               isSelected: recurringFrequency == freq) {
                        recurringFrequency = freq
                    }
                }
            }
            .padding(.horizontal, BCSpacing.lg)

            Text("Tot wanneer?")
                .font(et.body)
                .foregroundStyle(BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.xs)

            VStack(spacing: BCSpacing.sm) {
                ForEach(endDatePresets, id: \.label) { preset in
                    TimingTile(title: preset.label, subtitle: preset.subtitle, icon: preset.icon,
                               isSelected: !useCustomEndDate && Calendar.current.isDate(recurringEndDate, inSameDayAs: preset.date)) {
                        useCustomEndDate = false
                        recurringEndDate = preset.date
                    }
                }
                TimingTile(title: "Zelf kiezen", subtitle: "Kies een einddatum",
                           icon: "calendar.badge.clock", isSelected: useCustomEndDate) {
                    useCustomEndDate = true
                }
                if useCustomEndDate {
                    DatePicker("", selection: $recurringEndDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(BCColors.accent)
                        .padding(BCSpacing.md)
                        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                        .bcSoftShadow(.card)
                }
            }
            .padding(.horizontal, BCSpacing.lg)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var endDatePresets: [(label: String, subtitle: String, icon: String, date: Date)] {
        let cal = Calendar.current
        let now = Date()
        return [
            ("1 week",  "t/m \(formatted(cal.date(byAdding: .weekOfYear, value: 1, to: now)!))",  "calendar",            cal.date(byAdding: .weekOfYear, value: 1, to: now)!),
            ("2 weken", "t/m \(formatted(cal.date(byAdding: .weekOfYear, value: 2, to: now)!))",  "calendar",            cal.date(byAdding: .weekOfYear, value: 2, to: now)!),
            ("1 maand", "t/m \(formatted(cal.date(byAdding: .month,     value: 1, to: now)!))",   "calendar.badge.plus", cal.date(byAdding: .month,      value: 1, to: now)!),
        ]
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "nl_NL"); f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    private var tomorrowAt10: Date {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return cal.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    // STEP 2 — bevestiging
    private var confirmStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                Text("Klopt dit?")
                    .font(BCTypography.elderlyHeading)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        SummaryRow(label: "Soort hulp", value: selectedCategory?.displayName ?? "—",
                                   icon: selectedCategory?.icon ?? "questionmark")
                        Divider()
                        SummaryRow(label: "Wanneer", value: selectedTiming?.displayName ?? "—", icon: "clock.fill")
                        if let sched = recurringSchedule {
                            Divider()
                            SummaryRow(label: "Herhaling", value: sched.displayName, icon: "repeat")
                        }
                        Divider()
                        SummaryRow(label: "Adres", value: targetElderly.address, icon: "house.fill")
                        if !note.isEmpty {
                            Divider()
                            SummaryRow(label: "Opmerking", value: note, icon: "text.bubble.fill")
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                extrasSection

                BCCard {
                    VStack(spacing: BCSpacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isRecurring ? "Tarief per bezoek" : "Geschat tarief")
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textSecondary)
                                Text(formattedPrice)
                                    .font(BCTypography.title2)
                                    .foregroundStyle(BCColors.navy900)
                                if isRecurring {
                                    Text("Elke keer apart verrekend via uw tegoed")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textTertiary)
                                }
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(BCColors.accent.opacity(0.15))
                                Image(systemName: isRecurring ? "repeat" : "creditcard.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(BCColors.green700)
                            }
                            .frame(width: 56, height: 56)
                        }
                        if !selectedExtras.isEmpty {
                            Divider()
                            HStack {
                                Text("Extra's (nu te betalen)")
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textSecondary)
                                Spacer()
                                Text(RequestExtra.formatCents(selectedExtrasTotalCents))
                                    .font(BCTypography.headline)
                                    .foregroundStyle(BCColors.navy900)
                            }
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                Text(selectedExtras.isEmpty
                     ? "Door op Bevestigen te tikken vraagt u officieel hulp aan. We zoeken meteen iemand in de buurt voor u."
                     : "U rekent eerst de gekozen extra's af. Daarna zetten we de aanvraag in en zoeken meteen iemand voor u.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
                    .padding(.horizontal, BCSpacing.lg)
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    private var formattedPrice: String {
        guard let cat = selectedCategory else { return "—" }
        let euros = Double(cat.suggestedPriceCents) / 100
        return String(format: "€ %.2f", euros).replacingOccurrences(of: ".", with: ",")
    }

    private var selectedExtrasTotalCents: Int {
        selectedExtras.reduce(0) { $0 + $1.priceCents }
    }

    private var confirmButtonTitle: String {
        guard step == 2 else { return "Volgende" }
        return selectedExtras.isEmpty ? "Bevestigen" : "Extra's afrekenen"
    }

    // MARK: - Betaalde extra's (boosts)

    private var extrasSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BCColors.accent)
                Text("Sneller of zekerder geholpen?")
                    .font(BCTypography.headline)
                    .foregroundStyle(BCColors.textPrimary)
            }
            Text("Optioneel — kleine toeslag, direct te betalen.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)

            VStack(spacing: BCSpacing.sm) {
                ForEach(RequestExtra.allCases) { extra in
                    ExtraToggleCard(extra: extra, isSelected: selectedExtras.contains(extra)) {
                        if selectedExtras.contains(extra) {
                            selectedExtras.remove(extra)
                        } else {
                            selectedExtras.insert(extra)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
        .animation(.easeInOut(duration: 0.15), value: selectedExtras)
    }

    private var bottomBar: some View {
        VStack(spacing: BCSpacing.sm) {
            Divider()
            HStack(spacing: BCSpacing.sm) {
                if step > 0 {
                    BCSecondaryButton(title: "Terug", icon: "chevron.left", fullWidth: true) {
                        step -= 1
                    }
                }
                BCCTAButton(
                    title: confirmButtonTitle,
                    icon: step == 2 ? (selectedExtras.isEmpty ? "checkmark" : "creditcard.fill") : "arrow.right",
                    fullWidth: true
                ) {
                    next()
                }
                .opacity(canContinue ? 1.0 : 0.5)
                .disabled(!canContinue)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.md)
        }
        .background(BCColors.background)
    }

    private var canContinue: Bool {
        switch step {
        case 0: return selectedCategory != nil && (selectedCategory != .other || !otherDescription.isEmpty)
        case 1: return selectedTiming != nil && (!isRecurring || recurringEndDate > Date())
        case 2: return true
        default: return false
        }
    }

    private func next() {
        if step < 2 {
            step += 1
        } else if selectedExtras.isEmpty {
            submit(purchase: nil)
        } else {
            // Eerst de gekozen extra's afrekenen via de (demo-)betaalflow.
            showCheckout = true
        }
    }

    private func submit(purchase: Purchase?) {
        guard let cat = selectedCategory, let timing = selectedTiming else { return }
        let finalNote = cat == .other && !otherDescription.isEmpty
            ? (otherDescription + (note.isEmpty ? "" : "\n\(note)"))
            : note
        if let elderly = onBehalfOf {
            appState.requestHelpOnBehalf(for: elderly, category: cat, timing: timing,
                                         note: finalNote, recurringSchedule: recurringSchedule,
                                         extras: selectedExtras, purchase: purchase)
        } else {
            appState.requestHelp(category: cat, timing: timing, note: finalNote,
                                 recurringSchedule: recurringSchedule,
                                 extras: selectedExtras, purchase: purchase)
        }
        dismiss()
        // De auto-acceptatie na 5s wordt nu in AppState.requestHelp geregeld,
        // zodat hij betrouwbaar draait ook nadat dit scherm gesloten is.
    }
}

// MARK: - Smart recognition

private func recognizeCategory(from text: String) -> TaskCategory? {
    guard text.count > 3 else { return nil }
    let t = text.lowercased()
    let rules: [(words: [String], category: TaskCategory)] = [
        (["boodschap", "supermarkt", "winkel", "inkopen", "winkelen", "albert", "jumbo", "halen"],       .groceries),
        (["medicatie", "medicijn", "pil", "pillen", "tablet", "apotheek", "medicijnen", "bloeddruk"],    .medicationReminder),
        (["schoon", "opruim", "stofzuig", "poets", "huishoud", "dweilen", "afwas", "rommel"],            .lightCleaning),
        (["koffie", "gezelschap", "praatje", "praten", "kletsen", "eenzaam", "samen", "spelletje"],      .companionship),
        (["eten", "maaltijd", "koken", "lunch", "middageten", "avondeten", "soep", "warm maken"],         .mealPrep),
        (["bed", "opstaan", "aankleden", "uitkleden", "pyjama", "slapen", "liggen"],                     .bedHelp),
        (["wandel", "lopen", "buiten", "ommetje", "frisse lucht", "park"],                               .walkOutdoors),
        (["dokter", "ziekenhuis", "afspraak", "arts", "specialist", "fysiotherapeut", "tandarts"],       .appointment),
    ]
    for rule in rules {
        if rule.words.contains(where: { t.contains($0) }) { return rule.category }
    }
    return nil
}

private struct CategoryTile: View {
    @Environment(\.largeTextEnabled) private var largeText
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        Button(action: action) {
            if largeText {
                // Large: horizontal layout for 1-column rows
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(isSelected ? BCColors.navy900 : BCColors.navy900.opacity(0.08))
                        Image(systemName: category.icon)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : BCColors.navy700)
                    }
                    .frame(width: 68, height: 68)
                    Text(category.displayName)
                        .font(et.button)
                        .foregroundStyle(BCColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(BCColors.navy700)
                    }
                }
                .padding(BCSpacing.md)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).stroke(isSelected ? BCColors.navy700 : Color.clear, lineWidth: 2))
                .bcSoftShadow(.card)
            } else {
                // Normal: vertical layout for 2-column grid
                VStack(spacing: BCSpacing.xs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(isSelected ? BCColors.navy900 : BCColors.navy900.opacity(0.08))
                        Image(systemName: category.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : BCColors.navy700)
                    }
                    .frame(width: 56, height: 56)
                    Text(category.displayName)
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(BCSpacing.md)
                .frame(maxWidth: .infinity, minHeight: 130)
                .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).stroke(isSelected ? BCColors.navy700 : Color.clear, lineWidth: 2))
                .bcSoftShadow(.card)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct TimingTile: View {
    @Environment(\.largeTextEnabled) private var largeText
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(isSelected ? BCColors.navy900 : BCColors.navy900.opacity(0.08))
                    Image(systemName: icon)
                        .font(.system(size: largeText ? 28 : 22, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : BCColors.navy700)
                }
                .frame(width: largeText ? 60 : 48, height: largeText ? 60 : 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    if !largeText {
                        Text(subtitle)
                            .font(et.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: largeText ? 28 : 22, weight: .semibold))
                        .foregroundStyle(BCColors.navy700)
                }
            }
            .padding(largeText ? BCSpacing.lg : BCSpacing.md)
            .frame(maxWidth: .infinity, minHeight: largeText ? 88 : 72)
            .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
            .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).stroke(isSelected ? BCColors.navy700 : Color.clear, lineWidth: 2))
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BCColors.primary)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                Text(value)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Extra-keuzekaart (boost)

private struct ExtraToggleCard: View {
    let extra: RequestExtra
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(isSelected ? BCColors.accent : BCColors.accent.opacity(0.12))
                    Image(systemName: extra.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isSelected ? BCColors.navy900 : BCColors.green700)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: BCSpacing.xs) {
                        Text(extra.displayName)
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("+ \(extra.priceFormatted)")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.green700)
                    }
                    Text(extra.description)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: BCSpacing.sm)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? BCColors.green600 : BCColors.textTertiary)
            }
            .padding(BCSpacing.md)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
            .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .stroke(isSelected ? BCColors.green600 : Color.clear, lineWidth: 2))
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Demo-checkout voor betaalde extra's

private struct ExtrasCheckoutSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let extras: [RequestExtra]
    let basePriceCents: Int
    let onPaid: (Purchase) -> Void

    @State private var isPaying = false
    @State private var errorMessage: String? = nil

    private var extrasTotalCents: Int { extras.reduce(0) { $0 + $1.priceCents } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.lg) {
                    header

                    BCCard {
                        VStack(spacing: BCSpacing.sm) {
                            ForEach(extras) { extra in
                                HStack(spacing: BCSpacing.md) {
                                    Image(systemName: extra.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(BCColors.green700)
                                        .frame(width: 28)
                                    Text(extra.displayName)
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Spacer()
                                    Text(extra.priceFormatted)
                                        .font(BCTypography.bodyEmphasized)
                                        .foregroundStyle(BCColors.textPrimary)
                                }
                                if extra != extras.last { Divider() }
                            }
                            Divider()
                            HStack {
                                Text("Totaal")
                                    .font(BCTypography.headline)
                                    .foregroundStyle(BCColors.textPrimary)
                                Spacer()
                                Text(RequestExtra.formatCents(extrasTotalCents))
                                    .font(BCTypography.title2)
                                    .foregroundStyle(BCColors.navy900)
                            }
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    HStack(spacing: BCSpacing.xs) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Demo-betaling — er wordt geen echt geld afgeschreven.")
                            .font(BCTypography.caption)
                    }
                    .foregroundStyle(BCColors.textTertiary)
                    .padding(.horizontal, BCSpacing.lg)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(BCTypography.subheadline)
                            .foregroundStyle(BCColors.danger)
                            .padding(.horizontal, BCSpacing.lg)
                    }
                }
                .padding(.bottom, BCSpacing.lg)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Extra's afrekenen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") { dismiss() }
                        .tint(BCColors.primary)
                        .disabled(isPaying)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    BCCTAButton(
                        title: isPaying ? "Bezig met betalen…" : "Betaal \(RequestExtra.formatCents(extrasTotalCents))",
                        icon: isPaying ? "hourglass" : "creditcard.fill",
                        fullWidth: true
                    ) {
                        Task { await pay() }
                    }
                    .opacity(isPaying ? 0.6 : 1)
                    .disabled(isPaying)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.vertical, BCSpacing.md)
                }
                .background(BCColors.background)
            }
        }
        .interactiveDismissDisabled(isPaying)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BCSpacing.xs) {
            ZStack {
                Circle().fill(BCColors.accent.opacity(0.15))
                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(BCColors.green700)
            }
            .frame(width: 64, height: 64)
            .padding(.top, BCSpacing.md)
            Text("U boost uw aanvraag")
                .font(BCTypography.title2)
                .foregroundStyle(BCColors.textPrimary)
            Text("Na betaling zetten we de aanvraag meteen in.")
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    private func pay() async {
        isPaying = true
        errorMessage = nil
        let result = await appState.paymentService.charge(extras: extras, taskID: nil)
        isPaying = false
        switch result {
        case .success(let purchase):
            onPaid(purchase)
        case .failure(let message):
            errorMessage = message
        }
    }
}

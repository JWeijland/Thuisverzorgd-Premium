import Foundation
import CoreLocation

enum MockData {
    static let amsterdamCenter = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)

    static let omaRiet = ElderlyUser(
        id: UUID(),
        firstName: "Riet",
        lastName: "van der Berg",
        address: "Elandsgracht 86, Amsterdam",
        coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1948, month: 3, day: 12))!,
        phoneNumber: "06 12 34 56 78",
        allergies: ["Penicilline"],
        medicationNotes: "2x daags bloeddrukpil — om 08:00 en 20:00",
        favoriteBuddyIDs: [],
        familyMemberIDs: [],
        creditEuros: 10.0
    )

    static let opaHenk = ElderlyUser(
        id: UUID(),
        firstName: "Henk",
        lastName: "de Boer",
        address: "Ferdinand Bolstraat 45, Amsterdam",
        coordinate: CLLocationCoordinate2D(latitude: 52.3534, longitude: 4.8993),
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1940, month: 7, day: 4))!,
        phoneNumber: "06 98 76 54 32",
        allergies: [],
        medicationNotes: "Bloeddrukmedicatie — ochtend",
        favoriteBuddyIDs: [],
        familyMemberIDs: [],
        creditEuros: 0.0
    )

    static let buddyAiyla = BuddyUser(
        id: UUID(),
        firstName: "Aiyla",
        lastName: "Demir",
        avatarSystemName: "person.crop.circle.fill",
        level: .one,
        certifications: [
            Certification(id: UUID(), level: .zero, issuedAt: Date().addingTimeInterval(-86400 * 90), expiresAt: Date().addingTimeInterval(86400 * 365 * 2)),
            Certification(id: UUID(), level: .one, issuedAt: Date().addingTimeInterval(-86400 * 30), expiresAt: Date().addingTimeInterval(86400 * 365 * 2))
        ],
        ratingAverage: 4.9,
        totalTasks: 47,
        bio: "Hallo! Ik ben Aiyla, 21 jaar en HBO-V student in Amsterdam. Ik help graag met gezelschap en lichte zorgtaken.",
        study: "HBO-V — jaar 2, Hogeschool van Amsterdam",
        kycVerified: true,
        vogValid: true,
        vogExpiresAt: Date().addingTimeInterval(86400 * 365 * 3),
        ibanLast4: "2481",
        isAvailableNow: true,
        coordinate: CLLocationCoordinate2D(latitude: 52.3745, longitude: 4.8900),
        maxDistanceKm: 8,
        completedTasksByCategory: [
            .companionship: 12,
            .groceries: 8,
            .walkOutdoors: 5,
            .lightCleaning: 4,
            .bedHelp: 3
        ],
        servicePreferences: [
            .zero: ["Gezelschap", "Boodschappen", "Wandelen", "Lichte huishouding", "Voorlezen", "Spelletjes"],
            .one:  ["Opstaan / naar bed", "Aankleden", "Maaltijdbereiding"]
        ]
    )

    static let buddyMark = BuddyUser(
        id: UUID(),
        firstName: "Mark",
        lastName: "Janssen",
        avatarSystemName: "person.crop.circle.fill",
        level: .two,
        certifications: [],
        ratingAverage: 4.7,
        totalTasks: 112,
        bio: "Ervaren buddy met zorgachtergrond. Beschikbaar in de avonden.",
        study: "Sociale Studies — afgerond",
        kycVerified: true,
        vogValid: true,
        vogExpiresAt: Date().addingTimeInterval(86400 * 365 * 2),
        ibanLast4: "9012",
        isAvailableNow: false,
        coordinate: CLLocationCoordinate2D(latitude: 52.3580, longitude: 4.9000),
        maxDistanceKm: 15,
        completedTasksByCategory: [
            .bedHelp: 28,
            .mealPrep: 22,
            .medicationReminder: 18,
            .companionship: 15,
            .appointment: 10
        ],
        servicePreferences: [
            .zero: ["Gezelschap", "Begeleiding afspraak", "Medicatieherinnering"],
            .one:  ["Opstaan / naar bed", "Aankleden", "Toiletbegeleiding", "Maaltijdbereiding", "Transfers"],
            .two:  ["Volledig wassen", "Medicatietoezicht", "Volledige ADL"]
        ]
    )

    static let buddySophie = BuddyUser(
        id: UUID(),
        firstName: "Sophie",
        lastName: "de Wit",
        avatarSystemName: "person.crop.circle.fill",
        level: .zero,
        certifications: [],
        ratingAverage: 4.6,
        totalTasks: 8,
        bio: "Geneeskundestudent, hou van koffie drinken en kletsen.",
        study: "Geneeskunde — jaar 1, Amsterdam UMC",
        kycVerified: true,
        vogValid: true,
        vogExpiresAt: Date().addingTimeInterval(86400 * 365 * 3),
        ibanLast4: "3344",
        isAvailableNow: true,
        coordinate: CLLocationCoordinate2D(latitude: 52.3700, longitude: 4.8950),
        maxDistanceKm: 5,
        completedTasksByCategory: [
            .companionship: 4,
            .lightCleaning: 2,
            .groceries: 2
        ],
        servicePreferences: [
            .zero: ["Gezelschap", "Voorlezen", "Lichte huishouding", "Boodschappen", "Spelletjes"]
        ]
    )

    static var allBuddies: [BuddyUser] { [buddyAiyla, buddyMark, buddySophie] }

    static let familySandra = FamilyUser(
        id: UUID(),
        firstName: "Sandra",
        lastName: "van der Berg",
        relationship: "Dochter van Riet",
        linkedElderlyIDs: [omaRiet.id]
    )

    // Open tasks visible on the buddy map
    static let openTasks: [ServiceTask] = [
        ServiceTask(
            id: UUID(),
            elderlyName: "Riet",
            elderlyAddress: "Elandsgracht 86",
            coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
            category: .companionship,
            requiredLevel: .zero,
            timing: .now,
            note: "Een uurtje koffie en kletsen, ze voelt zich wat alleen vandaag.",
            priceCents: 1300,
            status: .open,
            createdAt: Date().addingTimeInterval(-300),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Henk",
            elderlyAddress: "Ferdinand Bolstraat 45",
            coordinate: CLLocationCoordinate2D(latitude: 52.3534, longitude: 4.8993),
            category: .groceries,
            requiredLevel: .zero,
            timing: .today(hour: 16),
            note: "Boodschappenlijstje ligt op de keukentafel.",
            priceCents: 1500,
            status: .open,
            createdAt: Date().addingTimeInterval(-1800),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Truus",
            elderlyAddress: "Keizersgracht 210",
            coordinate: CLLocationCoordinate2D(latitude: 52.3729, longitude: 4.8851),
            category: .mealPrep,
            requiredLevel: .one,
            timing: .today(hour: 18),
            note: "Maaltijd opwarmen en samen eten.",
            priceCents: 1800,
            status: .open,
            createdAt: Date().addingTimeInterval(-2400),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Kees",
            elderlyAddress: "Weesperzijde 112",
            coordinate: CLLocationCoordinate2D(latitude: 52.3558, longitude: 4.9195),
            category: .walkOutdoors,
            requiredLevel: .zero,
            timing: .now,
            note: "Een kort rondje langs het park, ongeveer 30 minuten.",
            priceCents: 1300,
            status: .open,
            createdAt: Date().addingTimeInterval(-600),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Beatrix",
            elderlyAddress: "Minervalaan 78",
            coordinate: CLLocationCoordinate2D(latitude: 52.3453, longitude: 4.8732),
            category: .lightCleaning,
            requiredLevel: .zero,
            timing: .scheduled(date: Date().addingTimeInterval(86400)),
            note: "Stofzuigen en de afwas wegzetten.",
            priceCents: 1500,
            status: .open,
            createdAt: Date().addingTimeInterval(-3600),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Wim",
            elderlyAddress: "Middenweg 44",
            coordinate: CLLocationCoordinate2D(latitude: 52.3532, longitude: 4.9272),
            category: .medicationReminder,
            requiredLevel: .two,
            timing: .today(hour: 20),
            note: "Toezicht houden bij avondmedicatie volgens schema.",
            priceCents: 2200,
            status: .open,
            createdAt: Date().addingTimeInterval(-900),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Greet",
            elderlyAddress: "Bilderdijkstraat 159",
            coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.8716),
            category: .companionship,
            requiredLevel: .zero,
            timing: .now,
            note: "Even gezelschap, samen de krant doornemen.",
            priceCents: 1300,
            status: .open,
            createdAt: Date().addingTimeInterval(-180),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Johan",
            elderlyAddress: "Czaar Peterstraat 22",
            coordinate: CLLocationCoordinate2D(latitude: 52.3711, longitude: 4.9241),
            category: .groceries,
            requiredLevel: .zero,
            timing: .now,
            note: "Kleine boodschappen bij de buurtsuper.",
            priceCents: 1200,
            status: .open,
            createdAt: Date().addingTimeInterval(-420),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Annie",
            elderlyAddress: "Van Woustraat 88",
            coordinate: CLLocationCoordinate2D(latitude: 52.3556, longitude: 4.8967),
            category: .appointment,
            requiredLevel: .one,
            timing: .today(hour: 14),
            note: "Begeleiding naar de huisarts en weer terug.",
            priceCents: 1900,
            status: .open,
            createdAt: Date().addingTimeInterval(-1500),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Cor",
            elderlyAddress: "Javastraat 130",
            coordinate: CLLocationCoordinate2D(latitude: 52.3631, longitude: 4.9335),
            category: .walkOutdoors,
            requiredLevel: .zero,
            timing: .now,
            note: "Een frisse neus halen in het Oosterpark.",
            priceCents: 1300,
            status: .open,
            createdAt: Date().addingTimeInterval(-240),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Ria",
            elderlyAddress: "Admiraal de Ruijterweg 200",
            coordinate: CLLocationCoordinate2D(latitude: 52.3784, longitude: 4.8589),
            category: .lightCleaning,
            requiredLevel: .zero,
            timing: .today(hour: 11),
            note: "Wat opruimen en bed verschonen.",
            priceCents: 1500,
            status: .open,
            createdAt: Date().addingTimeInterval(-2100),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Sjaak",
            elderlyAddress: "Plantage Middenlaan 14",
            coordinate: CLLocationCoordinate2D(latitude: 52.3669, longitude: 4.9089),
            category: .mealPrep,
            requiredLevel: .one,
            timing: .today(hour: 17),
            note: "Samen koken en de maaltijd klaarzetten.",
            priceCents: 1800,
            status: .open,
            createdAt: Date().addingTimeInterval(-1200),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Els",
            elderlyAddress: "Haarlemmerdijk 102",
            coordinate: CLLocationCoordinate2D(latitude: 52.3852, longitude: 4.8898),
            category: .bedHelp,
            requiredLevel: .two,
            timing: .today(hour: 21),
            note: "Hulp bij het naar bed gaan en steunkousen uit.",
            priceCents: 2400,
            status: .open,
            createdAt: Date().addingTimeInterval(-720),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        )
    ]

    static let completedTasks: [ServiceTask] = [
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Riet",
                elderlyAddress: "Elandsgracht 86",
                coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
                category: .companionship,
                requiredLevel: .zero,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 2)),
                note: "Koffie drinken en samen kruiswoordpuzzel.",
                priceCents: 1300,
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 2),
                assignedBuddyName: "Aiyla",
                assignedBuddyRating: 4.9,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 2 + 3600)
            t.completionNote = "Riet was vrolijk, samen koffie gedronken en wat over haar kleinkinderen gepraat."
            return t
        }(),
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Riet",
                elderlyAddress: "Elandsgracht 86",
                coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
                category: .groceries,
                requiredLevel: .zero,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 5)),
                note: "Boodschappenlijstje van AH halen.",
                priceCents: 1500,
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 5),
                assignedBuddyName: "Sophie",
                assignedBuddyRating: 4.6,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 5 + 5400)
            t.completionNote = "Boodschappen gedaan, alles netjes opgeruimd in de keuken."
            return t
        }(),
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Riet",
                elderlyAddress: "Elandsgracht 86",
                coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
                category: .walkOutdoors,
                requiredLevel: .zero,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 9)),
                note: "Een ommetje langs het park.",
                priceCents: 1300,
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 9),
                assignedBuddyName: "Aiyla",
                assignedBuddyRating: 4.9,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 9 + 2700)
            t.completionNote = "Mooi weer, lekker gewandeld langs het Vondelpark."
            return t
        }(),
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Henk",
                elderlyAddress: "Ferdinand Bolstraat 45",
                coordinate: CLLocationCoordinate2D(latitude: 52.3534, longitude: 4.8993),
                category: .walkOutdoors,
                requiredLevel: .zero,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 3)),
                note: "Wandeling langs de Amstel.",
                priceCents: 1300,
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 3),
                assignedBuddyName: "Jan",
                assignedBuddyRating: 4.6,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 3 + 2700)
            t.completionNote = "Henk genoot van de frisse lucht, rustig tempo aangehouden."
            return t
        }(),
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Henk",
                elderlyAddress: "Ferdinand Bolstraat 45",
                coordinate: CLLocationCoordinate2D(latitude: 52.3534, longitude: 4.8993),
                category: .groceries,
                requiredLevel: .zero,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 7)),
                note: "Weekboodschappen halen.",
                priceCents: 1500,
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 7),
                assignedBuddyName: "Jan",
                assignedBuddyRating: 4.4,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 7 + 5400)
            t.completionNote = "Boodschappen gehaald en samen opgeruimd."
            return t
        }()
    ]

    static let courses: [Course] = CourseContent.allCourses

    static let earnings: [EarningEntry] = [
        EarningEntry(id: UUID(), date: Date().addingTimeInterval(-86400), elderlyName: "Riet", category: .companionship, amountCents: 1040),
        EarningEntry(id: UUID(), date: Date().addingTimeInterval(-86400 * 2), elderlyName: "Wim", category: .groceries, amountCents: 1200),
        EarningEntry(id: UUID(), date: Date().addingTimeInterval(-86400 * 3), elderlyName: "Truus", category: .mealPrep, amountCents: 1440),
        EarningEntry(id: UUID(), date: Date().addingTimeInterval(-86400 * 4), elderlyName: "Beatrix", category: .lightCleaning, amountCents: 1200),
        EarningEntry(id: UUID(), date: Date().addingTimeInterval(-86400 * 6), elderlyName: "Henk", category: .walkOutdoors, amountCents: 1040),
        EarningEntry(id: UUID(), date: Date().addingTimeInterval(-86400 * 7), elderlyName: "Riet", category: .companionship, amountCents: 1040),
        EarningEntry(id: UUID(), date: Date().addingTimeInterval(-86400 * 9), elderlyName: "Kees", category: .walkOutdoors, amountCents: 1040)
    ]

    // MARK: - Organisaties ("Takken")

    static let cordaan = Organization(
        id: UUID(),
        name: "Cordaan",
        shortName: "Cordaan",
        logoSymbol: "building.2.fill",
        buddyHourlyRateCents: 3500,
        markupPercent: 20.0,
        isActive: true
    )

    static var sampleServiceRecords: [ServiceRecord] {
        let orgId = cordaan.id
        return [
            ServiceRecord(
                id: UUID(), buddyName: "Petra Smits", elderlyName: "Riet van der Berg",
                organizationId: orgId, taskCategory: .companionship,
                hours: 1.5, buddyHourlyRateCents: 3500, clientHourlyRateCents: 4200,
                paymentType: .particulier, municipality: nil, month: "2026-05",
                completedAt: Date().addingTimeInterval(-86400 * 3), isFinalized: false
            ),
            ServiceRecord(
                id: UUID(), buddyName: "Jan de Vries", elderlyName: "Henk de Boer",
                organizationId: orgId, taskCategory: .groceries,
                hours: 2.0, buddyHourlyRateCents: 3500, clientHourlyRateCents: 4200,
                paymentType: .zinNatura, municipality: "Amsterdam", month: "2026-05",
                completedAt: Date().addingTimeInterval(-86400 * 5), isFinalized: false
            ),
            ServiceRecord(
                id: UUID(), buddyName: "Petra Smits", elderlyName: "Truus Vissers",
                organizationId: orgId, taskCategory: .mealPrep,
                hours: 1.0, buddyHourlyRateCents: 3500, clientHourlyRateCents: 4200,
                paymentType: .zinNatura, municipality: "Amsterdam", month: "2026-05",
                completedAt: Date().addingTimeInterval(-86400 * 7), isFinalized: false
            ),
            ServiceRecord(
                id: UUID(), buddyName: "Maria Hoekstra", elderlyName: "Kees Bakker",
                organizationId: orgId, taskCategory: .walkOutdoors,
                hours: 0.75, buddyHourlyRateCents: 3500, clientHourlyRateCents: 4200,
                paymentType: .particulier, municipality: nil, month: "2026-04",
                completedAt: Date().addingTimeInterval(-86400 * 40), isFinalized: true
            ),
            ServiceRecord(
                id: UUID(), buddyName: "Jan de Vries", elderlyName: "Beatrix Lammers",
                organizationId: orgId, taskCategory: .lightCleaning,
                hours: 2.5, buddyHourlyRateCents: 3500, clientHourlyRateCents: 4200,
                paymentType: .zinNatura, municipality: "Rotterdam", month: "2026-04",
                completedAt: Date().addingTimeInterval(-86400 * 42), isFinalized: true
            ),
            ServiceRecord(
                id: UUID(), buddyName: "Maria Hoekstra", elderlyName: "Riet van der Berg",
                organizationId: orgId, taskCategory: .walkOutdoors,
                hours: 1.25, buddyHourlyRateCents: 3500, clientHourlyRateCents: 4200,
                paymentType: .particulier, municipality: nil, month: "2026-04",
                completedAt: Date().addingTimeInterval(-86400 * 35), isFinalized: true
            ),
        ]
    }

    static var sampleMemberships: [OrganizationMembership] {
        [
            OrganizationMembership(
                id: UUID(), userId: UUID(), userName: "Petra Smits", userRole: .buddy,
                organizationId: cordaan.id, status: .pending,
                proofNote: "Personeelspas geüpload",
                submittedAt: Date().addingTimeInterval(-3600 * 2)
            ),
            OrganizationMembership(
                id: UUID(), userId: UUID(), userName: "Jan de Vries", userRole: .buddy,
                organizationId: cordaan.id, status: .approved,
                proofNote: "Arbeidscontract geüpload",
                submittedAt: Date().addingTimeInterval(-86400 * 5),
                reviewedAt: Date().addingTimeInterval(-86400 * 4)
            ),
            OrganizationMembership(
                id: UUID(), userId: UUID(), userName: "Truus Vissers", userRole: .elderly,
                organizationId: cordaan.id, status: .pending,
                proofNote: "Cliëntenkaart geüpload",
                submittedAt: Date().addingTimeInterval(-3600 * 5)
            ),
            OrganizationMembership(
                id: UUID(), userId: UUID(), userName: "Kees Bakker", userRole: .elderly,
                organizationId: cordaan.id, status: .approved,
                proofNote: "Beschikking Wmo geüpload",
                submittedAt: Date().addingTimeInterval(-86400 * 12),
                reviewedAt: Date().addingTimeInterval(-86400 * 11)
            ),
        ]
    }

    static let reviewsForBuddy: [Review] = [
        Review(id: UUID(), stars: 5, body: "Aiyla was zo lief voor mijn moeder. Ze maakt echt verbinding.", authorName: "Sandra (familielid van Riet)", date: Date().addingTimeInterval(-86400 * 2)),
        Review(id: UUID(), stars: 5, body: "Op tijd, vriendelijk en goed gewerkt.", authorName: "Wim, 81", date: Date().addingTimeInterval(-86400 * 5)),
        Review(id: UUID(), stars: 4, body: "Prima bezoek, kwam wel iets later dan afgesproken.", authorName: "Truus, 76", date: Date().addingTimeInterval(-86400 * 12))
    ]

    /// Activiteit per beheerde oudere, zodat de familie-tijdlijn meebeweegt met wie je beheert.
    static func familyActivity(for firstName: String) -> [ActivityItem] {
        switch firstName {
        case "Henk":
            return [
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 3), icon: "figure.walk", color: BCColors.accent, title: "Wandeling", detail: "Jan wandelde langs de Amstel met Henk. Notitie: rustig tempo, Henk genoot."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 7), icon: "bag.fill", color: BCColors.primary, title: "Boodschappen gedaan", detail: "Jan haalde de weekboodschappen en ruimde alles samen op."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 9), icon: "pills.fill", color: BCColors.level2, title: "Medicatie-reminder", detail: "Jan herinnerde Henk aan de ochtendmedicatie."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 12), icon: "checkmark.circle.fill", color: BCColors.success, title: "Koppeling gelukt", detail: "Henk is gekoppeld aan uw familie-account.")
            ]
        default: // Riet
            return [
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-3600 * 2), icon: "checkmark.circle.fill", color: BCColors.success, title: "Bezoek voltooid", detail: "Aiyla bracht een uur door met Riet. Notitie: Riet was vrolijk."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 2), icon: "bag.fill", color: BCColors.primary, title: "Boodschappen gedaan", detail: "Sophie deed boodschappen bij AH (€ 23,40 contant gegeven)."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 4), icon: "figure.walk", color: BCColors.accent, title: "Wandeling", detail: "Aiyla wandelde 30 min met Riet in het Heemraadspark."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 5), icon: "star.fill", color: BCColors.warning, title: "Beoordeling toegevoegd", detail: "Riet gaf Aiyla 5 sterren."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 8), icon: "pills.fill", color: BCColors.level2, title: "Medicatie-reminder", detail: "Mark was aanwezig bij de avondmedicatie.")
            ]
        }
    }
}

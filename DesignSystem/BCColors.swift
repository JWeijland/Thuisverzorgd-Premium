import SwiftUI

enum BCColors {
    // MARK: - Navy scale (from website tokens)
    // navy-900 #112F50, navy-700 #1A4878, navy-500 #2A6CB0
    static let navy900 = Color(red: 0.067, green: 0.184, blue: 0.314)
    static let navy700 = Color(red: 0.102, green: 0.282, blue: 0.471)
    static let navy500 = Color(red: 0.165, green: 0.424, blue: 0.690)

    // MARK: - Green scale (from website tokens)
    // green-500 #8DC93F, green-600 #73B02B
    static let green500 = Color(red: 0.553, green: 0.788, blue: 0.247)
    static let green600 = Color(red: 0.451, green: 0.690, blue: 0.169)
    static let green700 = Color(red: 0.353, green: 0.561, blue: 0.122)

    // MARK: - Brand roles
    static let primary = navy700
    static let primaryDark = navy900
    static let primaryMuted = navy700.opacity(0.08)

    // Accent is now the fresh green (was orange)
    static let accent = green500
    static let accentDark = green600

    // MARK: - Surfaces
    // Koel blauwgrijs #F5F8FC i.p.v. warm wit
    static let background = Color(red: 0.961, green: 0.973, blue: 0.988)
    static let surface = Color.white
    static let surfaceMuted = Color(red: 0.933, green: 0.949, blue: 0.973)

    // MARK: - Text
    static let textPrimary = Color(red: 0.067, green: 0.149, blue: 0.251)   // navy-tinted near-black
    static let textSecondary = Color(red: 0.353, green: 0.408, blue: 0.478)
    static let textTertiary = Color(red: 0.561, green: 0.604, blue: 0.667)

    static let border = Color(red: 0.890, green: 0.910, blue: 0.945)

    // MARK: - Semantic
    static let success = green600
    static let warning = Color(red: 0.882, green: 0.620, blue: 0.067)
    static let danger = Color(red: 0.851, green: 0.255, blue: 0.224)        // softened red #D9413A

    // MARK: - Buddy level pins (aligned to navy/green family)
    static let level0 = Color(red: 0.553, green: 0.612, blue: 0.671)
    static let level1 = navy500
    static let level2 = Color(red: 0.439, green: 0.275, blue: 0.604)
    static let level3 = Color(red: 0.851, green: 0.255, blue: 0.224)
    static let level4 = navy900
}

enum BCSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum BCRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let xl: CGFloat = 30
    static let pill: CGFloat = 999
}

// MARK: - Soft elevation (zachte schaduw i.p.v. harde randen)

extension View {
    /// Zachte, rustige kaartschaduw die past bij de website-vibe.
    func bcSoftShadow(_ strength: BCShadow = .card) -> some View {
        shadow(color: strength.color, radius: strength.radius, x: 0, y: strength.y)
    }
}

enum BCShadow {
    case card        // standaard kaart
    case raised      // hero / belangrijke kaart
    case subtle      // lichte hint

    var color: Color { BCColors.navy900.opacity(opacity) }
    var opacity: Double {
        switch self {
        case .card: return 0.06
        case .raised: return 0.10
        case .subtle: return 0.04
        }
    }
    var radius: CGFloat {
        switch self {
        case .card: return 12
        case .raised: return 20
        case .subtle: return 6
        }
    }
    var y: CGFloat {
        switch self {
        case .card: return 4
        case .raised: return 8
        case .subtle: return 2
        }
    }
}

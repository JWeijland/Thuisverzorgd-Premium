import SwiftUI
import UIKit

// MARK: - Font routing (Montserrat koppen + Open Sans tekst, met systeem-fallback)
//
// Zodra de fontbestanden in de bundle zitten (zie stuk 10) gebruiken alle
// tokens automatisch Montserrat/Open Sans. Is een font niet aanwezig, dan
// valt alles netjes terug op het afgeronde systeem-font — geen lelijke
// kale San Francisco en geen code-wijziging nodig.

enum BCFont {
    /// Naam van een geïnstalleerd custom font of nil als het niet bestaat.
    private static func installedName(_ candidates: [String]) -> String? {
        for name in candidates where UIFont(name: name, size: 12) != nil {
            return name
        }
        return nil
    }

    static func heading(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        let names: [String]
        switch weight {
        case .heavy, .black:       names = ["Montserrat-ExtraBold", "Montserrat-Bold"]
        case .bold:                names = ["Montserrat-Bold"]
        case .semibold, .medium:   names = ["Montserrat-SemiBold"]
        default:                   names = ["Montserrat-Medium", "Montserrat-Regular"]
        }
        if let n = installedName(names) { return .custom(n, size: size) }
        return .system(size: size, weight: weight, design: .rounded)
    }

    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let names: [String]
        switch weight {
        case .bold, .heavy, .black: names = ["OpenSans-Bold", "OpenSans-SemiBold"]
        case .semibold, .medium:    names = ["OpenSans-SemiBold"]
        default:                    names = ["OpenSans-Regular"]
        }
        if let n = installedName(names) { return .custom(n, size: size) }
        return .system(size: size, weight: weight, design: .rounded)
    }
}

enum BCTypography {
    // Standard mode (buddy/family) — koppen via Montserrat, tekst via Open Sans
    static let largeTitle        = BCFont.heading(34, .bold)
    static let title             = BCFont.heading(28, .bold)
    static let titleEmphasized   = BCFont.heading(22, .heavy)
    static let title2            = BCFont.heading(22, .semibold)
    static let title3            = BCFont.heading(20, .semibold)
    static let headline          = BCFont.heading(18, .semibold)
    static let body              = BCFont.body(17, .regular)
    static let bodyEmphasized    = BCFont.body(17, .semibold)
    static let subheadline       = BCFont.body(15, .regular)
    static let callout           = BCFont.body(16, .regular)
    static let caption           = BCFont.body(13, .regular)
    static let captionEmphasized = BCFont.body(13, .semibold)

    // Elderly mode — larger sizes, minimum 20pt body per accessibility spec
    static let elderlyTitle      = BCFont.heading(28, .bold)
    static let elderlyHeading    = BCFont.heading(24, .bold)
    static let elderlyBody       = BCFont.body(20, .regular)
    static let elderlyCaption    = BCFont.body(17, .regular)
    static let elderlyButton     = BCFont.heading(22, .semibold)
}

// MARK: - Elderly large-text scale

struct BCElderlyType {
    let large: Bool
    // Normal → Large: each step adds ~6pt
    var title:   Font { BCFont.heading(large ? 36 : 28, .bold) }
    var heading: Font { BCFont.heading(large ? 30 : 24, .bold) }
    var body:    Font { BCFont.body(large ? 26 : 20, .regular) }
    var caption: Font { BCFont.body(large ? 21 : 17, .regular) }
    var button:  Font { BCFont.heading(large ? 28 : 22, .semibold) }
    var iconBoxSize: CGFloat { large ? 88 : 72 }
    var iconSize:    CGFloat { large ? 40 : 32 }
    var tileHeight:  CGFloat { large ? 148 : 120 }
}

// MARK: - EnvironmentKey so every elderly view inherits the flag

private struct LargeTextEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var largeTextEnabled: Bool {
        get { self[LargeTextEnabledKey.self] }
        set { self[LargeTextEnabledKey.self] = newValue }
    }
}

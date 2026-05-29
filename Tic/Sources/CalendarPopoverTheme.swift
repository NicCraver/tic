import SwiftUI

enum CalendarPopoverTheme {
    static func palette(for scheme: ColorScheme) -> CalendarPalette {
        switch scheme {
        case .dark:
            CalendarPalette(
                appearance: .dark,
                background: Color(red: 0.07, green: 0.07, blue: 0.08),
                detailsBackground: Color(red: 0.11, green: 0.11, blue: 0.12),
                cardBackground: Color(red: 0.15, green: 0.15, blue: 0.17),
                controlBackground: Color.white.opacity(0.10),
                controlBorder: Color.white.opacity(0.14),
                holidayBackground: Color.accentColor.opacity(0.20),
                workdayBackground: Color.white.opacity(0.08),
                accent: Color.accentColor,
                primaryText: Color(red: 0.96, green: 0.96, blue: 0.97),
                secondaryText: Color(red: 0.65, green: 0.65, blue: 0.68),
                mutedText: Color.white.opacity(0.30),
                restBadge: Color.accentColor,
                workBadge: Color(red: 1.0, green: 0.48, blue: 0.10),
                dot: Color(red: 0.42, green: 0.42, blue: 0.45),
                separator: Color.white.opacity(0.10),
                shadow: Color.black.opacity(0.20)
            )
        default:
            CalendarPalette(
                appearance: .light,
                background: .white,
                detailsBackground: Color(red: 0.96, green: 0.96, blue: 0.96),
                cardBackground: .white,
                controlBackground: Color.black.opacity(0.04),
                controlBorder: Color.black.opacity(0.08),
                holidayBackground: Color.accentColor.opacity(0.10),
                workdayBackground: Color.black.opacity(0.04),
                accent: Color.accentColor,
                primaryText: Color(red: 0.02, green: 0.02, blue: 0.02),
                secondaryText: Color(red: 0.38, green: 0.38, blue: 0.40),
                mutedText: Color.black.opacity(0.28),
                restBadge: Color.accentColor,
                workBadge: Color(red: 1.0, green: 0.48, blue: 0.10),
                dot: Color(red: 0.73, green: 0.73, blue: 0.74),
                separator: Color.black.opacity(0.08),
                shadow: Color.black.opacity(0.05)
            )
        }
    }
}

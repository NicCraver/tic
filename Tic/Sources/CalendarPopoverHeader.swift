import SwiftUI

struct CalendarPopoverHeader: View {
    let monthNumber: Int
    let year: Int
    let relativeOffsetLabel: String?
    let themeToggleTitle: String
    let themeToggleSystemImage: String
    let palette: CalendarPalette
    let onShowMonthPicker: () -> Void
    let onToggleTheme: () -> Void
    let onShowSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Button(action: onShowMonthPicker) {
                    Text("\(monthNumber)月")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(palette.primaryText)
                        .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("选择月份")

                Button(action: onShowMonthPicker) {
                    Text(String(year))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.secondaryText)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("选择年份")

                if let relativeOffsetLabel {
                    Text(relativeOffsetLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(palette.accent)
                        .padding(.horizontal, 7)
                        .frame(height: 16)
                        .background(palette.accent.opacity(0.10), in: Capsule())
                        .overlay {
                            Capsule().strokeBorder(palette.accent.opacity(0.18))
                        }
                        .accessibilityLabel("相对今天\(relativeOffsetLabel)")
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                headerIconButton(
                    systemName: themeToggleSystemImage,
                    accessibilityLabel: "切换为\(themeToggleTitle)外观",
                    action: onToggleTheme
                )

                headerIconButton(
                    systemName: "gearshape.fill",
                    accessibilityLabel: "打开设置",
                    action: onShowSettings
                )
            }
        }
    }

    private func headerIconButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.primaryText)
                .frame(width: 24, height: 24)
                .background(palette.controlBackground, in: Circle())
                .overlay {
                    Circle().strokeBorder(palette.controlBorder)
                }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}

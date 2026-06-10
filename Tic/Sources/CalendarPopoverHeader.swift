import SwiftUI

struct CalendarPopoverHeader: View {
    let monthNumber: Int
    let year: Int
    let relativeOffsetLabel: String?
    let nextRestDayCountdownLabel: String?
    let palette: CalendarPalette
    let onShowMonthPicker: () -> Void
    let onPreviousMonth: () -> Void
    let onGoToToday: () -> Void
    let onNextMonth: () -> Void
    let onShowSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
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
                } else if let nextRestDayCountdownLabel {
                    Text(nextRestDayCountdownLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(palette.accent)
                        .padding(.horizontal, 7)
                        .frame(height: 16)
                        .background(palette.accent.opacity(0.10), in: Capsule())
                        .overlay {
                            Capsule().strokeBorder(palette.accent.opacity(0.18))
                        }
                        .accessibilityLabel("距离\(nextRestDayCountdownLabel)")
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                monthNavigationControl

                headerIconButton(
                    systemName: "gearshape.fill",
                    accessibilityLabel: "打开设置",
                    action: onShowSettings
                )
            }
        }
    }

    private var monthNavigationControl: some View {
        HStack(spacing: 0) {
            monthNavigationButton(
                systemName: "chevron.left",
                accessibilityLabel: "上个月",
                action: onPreviousMonth
            )

            divider

            Button(action: onGoToToday) {
                Text("今")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 30, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("回到今天")
            .help("回到今天")

            divider

            monthNavigationButton(
                systemName: "chevron.right",
                accessibilityLabel: "下个月",
                action: onNextMonth
            )
        }
        .foregroundStyle(palette.primaryText)
        .background(palette.controlBackground, in: Capsule())
        .overlay {
            Capsule().strokeBorder(palette.controlBorder)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.controlBorder)
            .frame(width: 1, height: 14)
            .accessibilityHidden(true)
    }

    private func monthNavigationButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 27, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
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

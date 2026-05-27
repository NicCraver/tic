import SwiftUI

struct MenuBarDateLabel: View {
    @AppStorage("showSeconds") private var showSeconds = true
    @AppStorage("dateFormatStyle") private var dateFormatStyle = DateFormatStyle.compact.rawValue
    @State private var now = Date.now

    private var updateInterval: TimeInterval {
        switch DateFormatStyle(rawValue: dateFormatStyle) ?? .compact {
        case .compact, .timeOnly:
            return showSeconds ? 1 : 60
        case .dateOnly:
            return 60
        }
    }

    var body: some View {
        Text(formattedDate(now))
            .monospacedDigit()
            .font(.system(size: 12))
            .task(id: updateInterval) {
                while !Task.isCancelled {
                    now = .now
                    try? await Task.sleep(for: .seconds(updateInterval))
                }
            }
    }

    private func formattedDate(_ date: Date) -> String {
        switch DateFormatStyle(rawValue: dateFormatStyle) ?? .compact {
        case .compact:
            let pattern = showSeconds ? "M月d日 HH:mm:ss" : "M月d日 HH:mm"
            return Self.format(date, pattern: pattern)

        case .timeOnly:
            let pattern = showSeconds ? "HH:mm:ss" : "HH:mm"
            return Self.format(date, pattern: pattern)

        case .dateOnly:
            return Self.format(date, pattern: "yyyy年M月d日")
        }
    }

    private static func format(_ date: Date, pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}

enum DateFormatStyle: String, CaseIterable, Identifiable {
    case compact
    case timeOnly
    case dateOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "5月27日 11:09:40"
        case .timeOnly: "仅时间"
        case .dateOnly: "仅日期"
        }
    }
}

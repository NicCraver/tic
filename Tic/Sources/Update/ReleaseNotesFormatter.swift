import Foundation

/// 将 GitHub Release / CHANGELOG 的 Markdown 转为适合弹窗阅读的纯文本。
enum ReleaseNotesFormatter {
    private static let sectionTitles: [(marker: String, title: String)] = [
        ("### Added", "新增"),
        ("### Changed", "改进"),
        ("### Fixed", "修复"),
        ("### Removed", "移除"),
        ("### Security", "安全"),
        ("### Deprecated", "弃用"),
    ]

    static func displayText(from body: String, maxLength: Int = 800) -> String {
        var lines = sanitize(body)
        guard !lines.isEmpty else {
            return "请前往 GitHub 查看完整更新说明。"
        }

        lines = lines.filter { !isVersionHeaderLine($0) && !isHorizontalRule($0) }
        lines = lines.map { replaceSectionHeader($0) }
        lines = lines.map { normalizeBullet($0) }
        lines = collapseBlankLines(in: lines)

        var text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            return "请前往 GitHub 查看完整更新说明。"
        }
        if text.count > maxLength {
            text = String(text.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
        }
        return text
    }

    private static func sanitize(_ body: String) -> [String] {
        body
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
    }

    private static func isVersionHeaderLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("## [") || trimmed.hasPrefix("# ")
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed == "---" || trimmed == "***" || trimmed == "___"
    }

    private static func replaceSectionHeader(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        for section in sectionTitles where trimmed == section.marker {
            return section.title
        }
        if trimmed.hasPrefix("### ") {
            return String(trimmed.dropFirst(4))
        }
        if trimmed.hasPrefix("## ") {
            return String(trimmed.dropFirst(3))
        }
        return line
    }

    private static func normalizeBullet(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- ") {
            return "• " + String(trimmed.dropFirst(2))
        }
        if trimmed.hasPrefix("* ") {
            return "• " + String(trimmed.dropFirst(2))
        }
        return line
    }

    private static func collapseBlankLines(in lines: [String]) -> [String] {
        var result: [String] = []
        var previousWasBlank = false
        for line in lines {
            let isBlank = line.trimmingCharacters(in: .whitespaces).isEmpty
            if isBlank {
                guard !previousWasBlank else { continue }
                previousWasBlank = true
                result.append("")
                continue
            }
            previousWasBlank = false
            result.append(line)
        }
        return result
    }
}

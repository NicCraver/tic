import Foundation

struct MenuBarLabelMetrics {
    let displayText: String
    let textSlotWidth: CGFloat
    let labelWidth: CGFloat
    let showsIcon: Bool
    let updateInterval: TimeInterval

    static func current(date: Date = .now) -> MenuBarLabelMetrics {
        let order = AppSettings.loadBlockOrder()
        let enabled = AppSettings.loadEnabledBlocks()
        let showSeconds = UserDefaults.standard.object(forKey: AppSettings.showSecondsKey) as? Bool ?? true
        let use24Hour = UserDefaults.standard.object(forKey: AppSettings.use24HourKey) as? Bool ?? true

        let sizingText = MenuBarDisplayComposer.sizingText(
            order: order,
            enabled: enabled,
            showSeconds: showSeconds,
            use24Hour: use24Hour
        )
        let textSlotWidth = MenuBarDisplayComposer.reservedTextWidth(for: sizingText)

        var labelWidth = textSlotWidth
        if MenuBarDisplayComposer.showsIcon(order: order, enabled: enabled) {
            labelWidth += MenuBarDisplayComposer.menuBarIconWidth + MenuBarDisplayComposer.iconTextSpacing
        }
        labelWidth += MenuBarDisplayComposer.labelHorizontalInset * 2

        let composed = MenuBarDisplayComposer.compose(
            date: date,
            order: order,
            enabled: enabled,
            showSeconds: showSeconds,
            use24Hour: use24Hour
        )

        let interval: TimeInterval = enabled.contains(.time) && showSeconds ? 1 : 60

        return MenuBarLabelMetrics(
            displayText: composed.isEmpty ? "Tic" : composed,
            textSlotWidth: textSlotWidth,
            labelWidth: labelWidth,
            showsIcon: MenuBarDisplayComposer.showsIcon(order: order, enabled: enabled),
            updateInterval: interval
        )
    }
}

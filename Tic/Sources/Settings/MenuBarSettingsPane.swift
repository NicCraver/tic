import SwiftUI

struct MenuBarSettingsPane: View {
    @AppStorage(AppSettings.showSecondsKey) private var showSeconds = true
    @AppStorage(AppSettings.use24HourKey) private var use24Hour = true

    @State private var blockOrder: [MenuBarBlock] = AppSettings.loadBlockOrder()
    @State private var enabledBlocks: Set<MenuBarBlock> = AppSettings.loadEnabledBlocks()
    @State private var showTimeOptions = false

    var body: some View {
        SettingsPaneScaffold(title: "菜单栏") {
            Form {
                Section {
                    HStack(spacing: 6) {
                        if MenuBarDisplayComposer.showsIcon(order: blockOrder, enabled: enabledBlocks) {
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 13))
                        }
                        Text(previewText)
                            .font(.system(size: 13))
                            .monospacedDigit()
                    }

                    HStack {
                        Text("使用右侧按钮调整顺序")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("重置顺序") {
                            AppSettings.resetMenuBarLayout()
                            blockOrder = AppSettings.loadBlockOrder()
                            enabledBlocks = AppSettings.loadEnabledBlocks()
                        }
                        .buttonStyle(.link)
                    }
                }

                Section {
                    ForEach(blockOrder) { block in
                        blockRow(block)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .onAppear {
            blockOrder = Self.normalizedOrder(blockOrder)
        }
        .onChange(of: blockOrder) { _, newValue in
            AppSettings.saveBlockOrder(newValue)
            notifyMenuBarChanged()
        }
        .onChange(of: enabledBlocks) { _, newValue in
            AppSettings.saveEnabledBlocks(newValue)
            notifyMenuBarChanged()
        }
        .onChange(of: showSeconds) { _, _ in notifyMenuBarChanged() }
        .onChange(of: use24Hour) { _, _ in notifyMenuBarChanged() }
        .sheet(isPresented: $showTimeOptions) {
            timeOptionsSheet
        }
    }

    private func blockRow(_ block: MenuBarBlock) -> some View {
        HStack(spacing: 8) {
            reorderButtons(for: block)

            Toggle(isOn: binding(for: block)) {
                HStack(spacing: 8) {
                    Text(block.title)
                    Spacer(minLength: 4)
                    Text(block.previewSample)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .toggleStyle(.checkbox)

            if block == .time {
                Button("选项…") {
                    showTimeOptions = true
                }
                .buttonStyle(.link)
            }
        }
    }

    private func reorderButtons(for block: MenuBarBlock) -> some View {
        VStack(spacing: 2) {
            Button {
                moveBlockUp(block)
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(blockOrder.first == block)

            Button {
                moveBlockDown(block)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(blockOrder.last == block)
        }
        .foregroundStyle(.secondary)
        .frame(width: 16)
    }

    private var previewText: String {
        MenuBarDisplayComposer.compose(
            date: .now,
            order: blockOrder,
            enabled: enabledBlocks,
            showSeconds: showSeconds,
            use24Hour: use24Hour
        )
    }

    private var timeOptionsSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间选项")
                .font(.headline)
            Form {
                Section {
                    Toggle("24 小时制", isOn: $use24Hour)
                    Toggle("显示秒", isOn: $showSeconds)
                }
            }
            .formStyle(.grouped)
            Spacer()
        }
        .padding(20)
        .frame(width: 300, height: 180)
    }

    private func binding(for block: MenuBarBlock) -> Binding<Bool> {
        Binding(
            get: { enabledBlocks.contains(block) },
            set: { enabled in
                if enabled {
                    enabledBlocks.insert(block)
                    if !blockOrder.contains(block) {
                        blockOrder.append(block)
                    }
                } else {
                    enabledBlocks.remove(block)
                }
            }
        )
    }

    private func moveBlockUp(_ block: MenuBarBlock) {
        guard let index = blockOrder.firstIndex(of: block), index > 0 else { return }
        blockOrder.swapAt(index, index - 1)
    }

    private func moveBlockDown(_ block: MenuBarBlock) {
        guard let index = blockOrder.firstIndex(of: block), index < blockOrder.count - 1 else { return }
        blockOrder.swapAt(index, index + 1)
    }

    private static func normalizedOrder(_ order: [MenuBarBlock]) -> [MenuBarBlock] {
        var result = order
        for block in MenuBarBlock.allCases where !result.contains(block) {
            result.append(block)
        }
        return result
    }

    private func notifyMenuBarChanged() {
        NotificationCenter.default.post(name: .menuBarSettingsDidChange, object: nil)
    }
}

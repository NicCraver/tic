import AppKit
import SwiftUI

@MainActor
@Observable
final class UpdateSession {
    let release: GitHubRelease
    let currentVersion: String
    let version: String
    let changelog: String

    var downloadProgress: Double?
    var isDownloading = false
    var errorMessage: String?

    private let downloader = UpdateDownloadManager()
    private var downloadTask: Task<Void, Never>?

    init(release: GitHubRelease, currentVersion: String, version: String) {
        self.release = release
        self.currentVersion = currentVersion
        self.version = version
        self.changelog = ReleaseNotesFormatter.displayText(from: release.body)
    }

    func startDownload(onFinished: @escaping () -> Void) {
        guard let dmgURL = release.dmgDownloadURL else {
            errorMessage = "未找到 DMG 安装包，请稍后重试。"
            return
        }

        downloadTask?.cancel()
        errorMessage = nil
        isDownloading = true
        downloadProgress = 0

        downloadTask = Task {
            do {
                guard let downloadsDir = FileManager.default.urls(
                    for: .downloadsDirectory,
                    in: .userDomainMask
                ).first else {
                    throw UpdateDownloadError.invalidResponse
                }

                let filename = dmgURL.lastPathComponent
                guard let destination = TrustedDownloadPolicy.safeDestinationURL(
                    filename: filename,
                    in: downloadsDir
                ), TrustedDownloadPolicy.isExpectedDMGFilename(filename, version: version) else {
                    throw UpdateDownloadError.untrustedURL
                }

                let fileURL = try await downloader.download(
                    from: dmgURL,
                    expectedVersion: version,
                    to: destination
                ) { [weak self] progress in
                    self?.downloadProgress = progress
                }

                guard !Task.isCancelled else { return }

                downloadProgress = 1
                isDownloading = false
                _ = await NSWorkspace.shared.open(fileURL)
                onFinished()
            } catch is CancellationError {
                isDownloading = false
                downloadProgress = nil
            } catch UpdateDownloadError.cancelled {
                isDownloading = false
                downloadProgress = nil
            } catch {
                isDownloading = false
                downloadProgress = nil
                errorMessage = error.localizedDescription
            }
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloader.cancel()
        isDownloading = false
        downloadProgress = nil
    }
}

struct UpdateAvailableView: View {
    @Bindable var session: UpdateSession
    let onClose: () -> Void

    private let installInstructions = """
    1. 下载完成后将自动打开 DMG 镜像。
    2. 将 Tic 拖入「应用程序」文件夹完成安装。
    3. 若提示无法验证开发者，请右键 Tic → 打开；或在终端执行：
       xattr -cr /Applications/Tic.app
    """

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            manualInstallBadge
            notesSection(title: "安装说明", body: installInstructions, height: 118)
            if !session.changelog.isEmpty {
                notesSection(title: "更新内容", body: session.changelog, height: 88)
            }
            if let errorMessage = session.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            if session.isDownloading {
                downloadProgressSection
            }
            actionButtons
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            guard !session.isDownloading, session.downloadProgress == nil, session.errorMessage == nil else { return }
            session.startDownload(onFinished: onClose)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("发现新版本")
                    .font(.headline)
                Text("版本 \(session.version)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var manualInstallBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
            Text("需手动安装")
                .font(.caption2)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
    }

    private func notesSection(title: String, body: String, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            ScrollView {
                Text(body)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: height)
            .padding(8)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var downloadProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("正在下载更新…")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: session.downloadProgress ?? 0)
                .progressViewStyle(.linear)
                .tint(.accentColor)
            Text("\(Int((session.downloadProgress ?? 0) * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack {
            if session.isDownloading {
                Button("取消") {
                    session.cancelDownload()
                    onClose()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
            } else if session.errorMessage != nil {
                Button("稍后") {
                    onClose()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("重试") {
                    session.startDownload(onFinished: onClose)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

@MainActor
enum UpdateAvailablePanel {
    private static var panel: NSPanel?
    private static var session: UpdateSession?

    static func show(release: GitHubRelease, currentVersion: String, version: String) {
        dismiss()

        let session = UpdateSession(release: release, currentVersion: currentVersion, version: version)
        self.session = session

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "软件更新"
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .windowBackgroundColor

        let hosting = NSHostingController(
            rootView: UpdateAvailableView(session: session) {
                dismiss()
            }
        )
        panel.contentViewController = hosting
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    static func dismiss() {
        session?.cancelDownload()
        session = nil
        panel?.close()
        panel = nil
    }
}

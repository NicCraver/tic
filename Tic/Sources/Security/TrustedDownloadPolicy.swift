import Foundation

/// 更新包下载与落盘的安全策略（域名白名单、文件名、路径约束）。
enum TrustedDownloadPolicy {
    static let repoOwner = "NicCraver"
    static let repoName = "tic"
    private static let githubHosts: Set<String> = ["github.com"]
    private static let cdnHosts: Set<String> = [
        "objects.githubusercontent.com",
        "release-assets.githubusercontent.com",
    ]
    static let maxDMGBytes: Int64 = 100 * 1024 * 1024

    /// 校验 GitHub Release DMG 下载 URL（HTTPS + 白名单 host + 路径/文件名）。
    ///
    /// 首次请求走 `github.com/.../releases/download/...`；302 后走 `release-assets.githubusercontent.com`，
    /// 文件名可能在 query 的 `filename=` 中而非 path 末段。
    static func isTrustedReleaseAssetURL(_ url: URL, expectedVersion: String) -> Bool {
        guard url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased()
        else { return false }

        let filename = expectedDMGFilename(version: expectedVersion)

        if githubHosts.contains(host) {
            let releasePrefix = "/\(repoOwner)/\(repoName)/releases/download/"
            return url.path.contains(releasePrefix) && url.lastPathComponent == filename
        }

        if cdnHosts.contains(host) {
            return urlReferencesFilename(url, filename: filename)
        }

        return false
    }

    static func expectedDMGFilename(version: String) -> String {
        "Tic-v\(version)-macOS.dmg"
    }

    private static func urlReferencesFilename(_ url: URL, filename: String) -> Bool {
        if url.lastPathComponent == filename { return true }
        return url.absoluteString.contains(filename)
    }

    /// 期望文件名：`Tic-v{semver}-macOS.dmg`
    static func isExpectedDMGFilename(_ filename: String, version: String) -> Bool {
        filename == expectedDMGFilename(version: version)
    }

    /// 在下载目录内构造安全目标路径，拒绝 `..`、路径分隔符与越界写入。
    static func safeDestinationURL(filename: String, in downloadsDirectory: URL) -> URL? {
        guard !filename.isEmpty,
              filename == (filename as NSString).lastPathComponent,
              !filename.contains("/"),
              !filename.contains("..")
        else { return nil }

        let destination = downloadsDirectory.appendingPathComponent(filename, isDirectory: false)
        let standardizedDirectory = downloadsDirectory.standardizedFileURL
        let standardizedDestination = destination.standardizedFileURL

        let directoryPath = standardizedDirectory.path
        let destinationPath = standardizedDestination.path
        guard destinationPath == directoryPath || destinationPath.hasPrefix(directoryPath + "/") else {
            return nil
        }
        return destination
    }

    static func isAcceptableDMGFile(at url: URL, expectedVersion: String) -> Bool {
        guard isExpectedDMGFilename(url.lastPathComponent, version: expectedVersion) else { return false }
        guard let size = fileSize(at: url) else { return false }
        return size > 0 && size <= maxDMGBytes
    }

    static func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let number = attributes[.size] as? NSNumber
        else { return nil }
        return number.int64Value
    }
}

enum HTTPBodySizeLimit {
    static let githubAPIBytes = 512 * 1024
    static let holidayJSONBytes = 2 * 1024 * 1024

    static func isWithinLimit(data: Data, maxBytes: Int) -> Bool {
        data.count <= maxBytes
    }

    static func isWithinLimit(contentLength: Int?, maxBytes: Int) -> Bool {
        guard let contentLength else { return true }
        return contentLength <= maxBytes
    }
}

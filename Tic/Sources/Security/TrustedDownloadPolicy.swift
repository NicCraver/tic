import Foundation

/// 更新包下载与落盘的安全策略（域名白名单、文件名、路径约束）。
enum TrustedDownloadPolicy {
    static let repoOwner = "NicCraver"
    static let repoName = "tic"
    static let allowedHosts: Set<String> = [
        "github.com",
        "objects.githubusercontent.com",
    ]
    static let maxDMGBytes: Int64 = 100 * 1024 * 1024

    /// 校验 GitHub Release DMG 下载 URL（HTTPS + 白名单 host + 路径 + 文件名）。
    static func isTrustedReleaseAssetURL(_ url: URL, expectedVersion: String) -> Bool {
        guard url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased(),
              allowedHosts.contains(host)
        else { return false }

        let path = url.path
        let releasePrefix = "/\(repoOwner)/\(repoName)/releases/download/"
        guard path.contains(releasePrefix) else { return false }

        let filename = url.lastPathComponent
        return isExpectedDMGFilename(filename, version: expectedVersion)
    }

    /// 期望文件名：`Tic-v{semver}-macOS.dmg`
    static func isExpectedDMGFilename(_ filename: String, version: String) -> Bool {
        filename == "Tic-v\(version)-macOS.dmg"
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
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64
        else { return false }
        return size > 0 && size <= maxDMGBytes
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

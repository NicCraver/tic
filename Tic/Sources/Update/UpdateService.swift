import Foundation
import os

struct GitHubRelease: Sendable {
    let tagName: String
    let name: String
    let body: String
    let htmlURL: URL
    let dmgDownloadURL: URL?
    let publishedAt: Date?
}

enum UpdateError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case rateLimited
    case apiError(statusCode: Int)
    case parseError
    case untrustedDownloadURL
    case responseTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "更新地址无效"
        case .invalidResponse:
            return "服务器响应无效"
        case .rateLimited:
            return "GitHub API 请求过于频繁，请稍后再试"
        case .apiError(let code):
            return "服务器返回错误（\(code)）"
        case .parseError:
            return "无法解析更新信息"
        case .untrustedDownloadURL:
            return "更新包地址未通过安全校验"
        case .responseTooLarge:
            return "服务器响应过大"
        }
    }
}

/// 通过 GitHub Releases API 检查新版本。
final class UpdateService: Sendable {
    private static let owner = "NicCraver"
    private static let repo = "tic"
    private static let releasesURL =
        "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    static var releasesPageURL: URL {
        URL(string: "https://github.com/\(owner)/\(repo)/releases")!
    }

    private let logger = Logger(subsystem: "me.nic.tic", category: "UpdateService")
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    func checkForUpdates() async throws -> GitHubRelease? {
        guard let url = URL(string: Self.releasesURL) else {
            throw UpdateError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Tic/\(Self.currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidResponse
        }

        if httpResponse.statusCode == 403 || httpResponse.statusCode == 429 {
            throw UpdateError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            logger.error("GitHub API 返回状态码 \(httpResponse.statusCode)")
            throw UpdateError.apiError(statusCode: httpResponse.statusCode)
        }

        let contentLength = httpResponse.expectedContentLength > 0
            ? Int(httpResponse.expectedContentLength)
            : nil
        guard HTTPBodySizeLimit.isWithinLimit(
            contentLength: contentLength,
            maxBytes: HTTPBodySizeLimit.githubAPIBytes
        ), HTTPBodySizeLimit.isWithinLimit(data: data, maxBytes: HTTPBodySizeLimit.githubAPIBytes) else {
            throw UpdateError.responseTooLarge
        }

        let release = try parseRelease(data: data)
        let latestVersion = stripVersionPrefix(release.tagName)
        guard isNewer(latest: latestVersion, current: Self.currentVersion) else {
            return nil
        }
        guard let dmgURL = release.dmgDownloadURL,
              TrustedDownloadPolicy.isTrustedReleaseAssetURL(dmgURL, expectedVersion: latestVersion)
        else {
            logger.error("Release DMG URL 未通过安全校验")
            throw UpdateError.untrustedDownloadURL
        }
        return release
    }

    /// 校验响应体积是否在上限内。`internal` 以便单元测试。
    func isWithinLimit(contentLength: Int?, data: Data) -> Bool {
        HTTPBodySizeLimit.isWithinLimit(contentLength: contentLength, maxBytes: HTTPBodySizeLimit.githubAPIBytes)
            && HTTPBodySizeLimit.isWithinLimit(data: data, maxBytes: HTTPBodySizeLimit.githubAPIBytes)
    }

    /// 解析 GitHub Releases API 响应。`internal` 以便单元测试。
    func parseRelease(data: Data) throws -> GitHubRelease {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String,
              let htmlURLString = json["html_url"] as? String,
              let htmlURL = URL(string: htmlURLString)
        else {
            throw UpdateError.parseError
        }

        let name = json["name"] as? String ?? tagName
        let body = json["body"] as? String ?? ""
        let version = stripVersionPrefix(tagName)
        var dmgDownloadURL: URL?
        if let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                guard let assetName = asset["name"] as? String,
                      TrustedDownloadPolicy.isExpectedDMGFilename(assetName, version: version),
                      let urlString = asset["browser_download_url"] as? String,
                      let url = URL(string: urlString),
                      TrustedDownloadPolicy.isTrustedReleaseAssetURL(url, expectedVersion: version)
                else { continue }
                dmgDownloadURL = url
                break
            }
        }

        var publishedAt: Date?
        if let dateString = json["published_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            publishedAt = formatter.date(from: dateString)
                ?? ISO8601DateFormatter().date(from: dateString)
        }

        return GitHubRelease(
            tagName: tagName,
            name: name,
            body: body,
            htmlURL: htmlURL,
            dmgDownloadURL: dmgDownloadURL,
            publishedAt: publishedAt
        )
    }

    func stripVersionPrefix(_ version: String) -> String {
        version.hasPrefix("v") ? String(version.dropFirst()) : version
    }

    func isNewer(latest: String, current: String) -> Bool {
        let latestParts = parseVersion(latest)
        let currentParts = parseVersion(current)
        for index in 0..<max(latestParts.count, currentParts.count) {
            let latestValue = index < latestParts.count ? latestParts[index] : 0
            let currentValue = index < currentParts.count ? currentParts[index] : 0
            if latestValue > currentValue { return true }
            if latestValue < currentValue { return false }
        }
        return false
    }

    private func parseVersion(_ version: String) -> [Int] {
        stripVersionPrefix(version)
            .split(separator: ".")
            .compactMap { Int($0) }
    }
}

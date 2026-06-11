import Foundation

enum UpdateDownloadError: LocalizedError {
    case invalidResponse
    case cancelled
    case untrustedURL
    case fileTooLarge
    case invalidFile

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "下载响应无效"
        case .cancelled:
            return "下载已取消"
        case .untrustedURL:
            return "下载地址未通过安全校验"
        case .fileTooLarge:
            return "安装包体积异常"
        case .invalidFile:
            return "安装包校验失败"
        }
    }
}

@MainActor
final class UpdateDownloadManager {
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var expectedVersion: String?

    func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
        session?.invalidateAndCancel()
        session = nil
        expectedVersion = nil
    }

    func download(
        from url: URL,
        expectedVersion: String,
        to destination: URL,
        onProgress: @escaping @MainActor (Double) -> Void
    ) async throws -> URL {
        guard TrustedDownloadPolicy.isTrustedReleaseAssetURL(url, expectedVersion: expectedVersion),
              TrustedDownloadPolicy.isExpectedDMGFilename(destination.lastPathComponent, version: expectedVersion)
        else {
            throw UpdateDownloadError.untrustedURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = UpdateDownloadDelegate(
                expectedVersion: expectedVersion,
                onProgress: { progress in
                    Task { @MainActor in onProgress(progress) }
                },
                onComplete: { result in
                    continuation.resume(with: result)
                }
            )

            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60 * 30
            config.waitsForConnectivity = false

            let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
            self.session = session
            self.expectedVersion = expectedVersion

            let task = session.downloadTask(with: url)
            delegate.destinationURL = destination
            downloadTask = task
            task.resume()
        }
    }
}

private final class UpdateDownloadDelegate: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    var destinationURL: URL?
    private let expectedVersion: String
    private var didComplete = false
    private let onProgress: @Sendable (Double) -> Void
    private let onComplete: @Sendable (Result<URL, Error>) -> Void

    init(
        expectedVersion: String,
        onProgress: @escaping @Sendable (Double) -> Void,
        onComplete: @escaping @Sendable (Result<URL, Error>) -> Void
    ) {
        self.expectedVersion = expectedVersion
        self.onProgress = onProgress
        self.onComplete = onComplete
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard let url = request.url,
              TrustedDownloadPolicy.isTrustedReleaseAssetURL(url, expectedVersion: expectedVersion)
        else {
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard !didComplete else { return }
        guard let destinationURL else {
            finish(.failure(UpdateDownloadError.invalidResponse))
            return
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: location.path)
            if let size = attributes[.size] as? Int64, size > TrustedDownloadPolicy.maxDMGBytes {
                try? FileManager.default.removeItem(at: location)
                finish(.failure(UpdateDownloadError.fileTooLarge))
                return
            }

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)

            guard TrustedDownloadPolicy.isAcceptableDMGFile(at: destinationURL, expectedVersion: expectedVersion) else {
                try? FileManager.default.removeItem(at: destinationURL)
                finish(.failure(UpdateDownloadError.invalidFile))
                return
            }

            finish(.success(destinationURL))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        if totalBytesExpectedToWrite > TrustedDownloadPolicy.maxDMGBytes {
            downloadTask.cancel()
            return
        }
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress(progress)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, !didComplete else { return }
        if (error as NSError).code == NSURLErrorCancelled {
            finish(.failure(UpdateDownloadError.cancelled))
        } else {
            finish(.failure(error))
        }
    }

    private func finish(_ result: Result<URL, Error>) {
        guard !didComplete else { return }
        didComplete = true
        onComplete(result)
    }
}

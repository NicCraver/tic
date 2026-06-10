import Foundation

enum UpdateDownloadError: LocalizedError {
    case invalidResponse
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "下载响应无效"
        case .cancelled:
            return "下载已取消"
        }
    }
}

@MainActor
final class UpdateDownloadManager {
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?

    func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
        session?.invalidateAndCancel()
        session = nil
    }

    func download(
        from url: URL,
        to destination: URL,
        onProgress: @escaping @MainActor (Double) -> Void
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = UpdateDownloadDelegate(
                onProgress: { progress in
                    Task { @MainActor in onProgress(progress) }
                },
                onComplete: { result in
                    continuation.resume(with: result)
                }
            )

            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            self.session = session

            let task = session.downloadTask(with: url)
            delegate.destinationURL = destination
            downloadTask = task
            task.resume()
        }
    }
}

private final class UpdateDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    var destinationURL: URL?
    private var didComplete = false
    private let onProgress: @Sendable (Double) -> Void
    private let onComplete: @Sendable (Result<URL, Error>) -> Void

    init(
        onProgress: @escaping @Sendable (Double) -> Void,
        onComplete: @escaping @Sendable (Result<URL, Error>) -> Void
    ) {
        self.onProgress = onProgress
        self.onComplete = onComplete
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
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
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

import Foundation

extension URLError {
    static let networkConnectionLostError = URLError(
        .networkConnectionLost,
        userInfo: [
            NSLocalizedDescriptionKey: "The network connection was lost",
        ])
}

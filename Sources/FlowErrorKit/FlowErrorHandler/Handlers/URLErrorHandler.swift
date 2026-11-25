import Foundation

/// Handles `URLError`.
struct URLErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? URLError else {
            return .pass(flowError)
        }
        
        switch error.code {
        case .cancelled:
            return .cancel
            
        case .timedOut:
            // "The request timed out."
            // To reproduce: turn Network Link Conditioner on with 100% packet loss
            // This error has a nice localized error message: show it.
            return .present(ErrorPresentation(
                flowError: flowError,
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark"))
            
        case .notConnectedToInternet:
            // "The Internet connection appears to be offline."
            // To reproduce: turn Airplane Mode on
            // This error has a nice localized error message: show it.
            return .present(ErrorPresentation(
                flowError: flowError,
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark"))
            
        case .networkConnectionLost:
            // "The network connection was lost."
            // This error has a nice localized error message: show it.
            return .present(ErrorPresentation(
                flowError: flowError,
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark"))
            
        case .cannotConnectToHost:
            // "Could not connect to the server."
            // To reproduce: turn the server off
            // This error has a nice localized error message: show it.
            return .present(ErrorPresentation(
                flowError: flowError,
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark"))
            
        case .cannotFindHost:
            // "A server with the specified hostname could not be found."
            // Too helpful for debugging to hide.
            return .present(ErrorPresentation(
                flowError: flowError,
                title: error.localizedDescription,
                message: error.failingURL?.host,
                systemImage: "wifi.exclamationmark"))
            
        case .internationalRoamingOff:
            // Too helpful to hide.
            return .present(ErrorPresentation(
                flowError: flowError,
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark"))
            
        case .appTransportSecurityRequiresSecureConnection,
                .secureConnectionFailed,
                .serverCertificateHasBadDate,
                .serverCertificateUntrusted,
                .serverCertificateHasUnknownRoot,
                .serverCertificateNotYetValid,
                .clientCertificateRejected,
                .clientCertificateRequired,
                .cannotLoadFromNetwork:
            // TLS and App Transport Security errors (see <NSURLError.h>),
            // and cannotLoadFromNetwork: too helpful for debugging to hide.
            return .present(ErrorPresentation(
                flowError: flowError,
                title: error.localizedDescription,
                message: error.failingURL?.host,
                systemImage: "exclamationmark.shield"))
            
        default:
            // Most URLErrors have an English or technical message that is not
            // suitable for user display.
            return .present(ErrorPresentation(flowError: flowError))
        }
    }
}

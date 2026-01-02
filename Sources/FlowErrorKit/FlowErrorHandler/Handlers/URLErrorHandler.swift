import Foundation

/// Handles `URLError`.
public struct URLErrorHandler: FlowErrorHandler {
    public func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? URLError else {
            // Not a URLError: pass to the next error handler.
            return .pass(flowError)
        }
        
        switch error.code {
        case .cancelled:
            return .cancel
            
        case .timedOut:
            // "La requête a expiré."
            // To reproduce: turn Network Link Conditioner on with 100% packet loss
            // This error has a nice localized error message: show it.
            return .present(ErrorPresentation(
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark",
                flowError: flowError))
            
        case .notConnectedToInternet:
            // "La connexion Internet semble interrompue."
            // To reproduce: turn plane mode on
            // This error has a nice localized error message: show it.
            return .present(ErrorPresentation(
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark",
                flowError: flowError))
            
        case .networkConnectionLost:
            // "La connexion réseau a été perdue."
            // This error has a nice localized error message: show it.
            return .present(ErrorPresentation(
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark",
                flowError: flowError))
            
        case .cannotConnectToHost:
            // "Connexion au serveur impossible."
            // To reproduce: turn server off
            // This error has a nice localized error message: show it.
            return .present(ErrorPresentation(
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark",
                flowError: flowError))
            
        case .cannotFindHost:
            // "A server with the specified hostname could not be found."
            // Too helpful for debugging to hide.
            return .present(ErrorPresentation(
                title: error.localizedDescription,
                message: error.failingURL?.host,
                systemImage: "wifi.exclamationmark",
                flowError: flowError))
            
        case .internationalRoamingOff:
            // Too helpful to hide.
            return .present(ErrorPresentation(
                title: error.localizedDescription,
                systemImage: "wifi.exclamationmark",
                flowError: flowError))
            
        case .appTransportSecurityRequiresSecureConnection,
                .secureConnectionFailed,
                .serverCertificateHasBadDate,
                .serverCertificateUntrusted,
                .serverCertificateHasUnknownRoot,
                .serverCertificateNotYetValid,
                .clientCertificateRejected,
                .clientCertificateRequired,
                .cannotLoadFromNetwork:
            // SSL errors (see <NSURLError.h>)
            // Too helpful for debugging to hide.
            return .present(ErrorPresentation(
                title: error.localizedDescription,
                message: error.failingURL?.host,
                systemImage: "exclamationmark.shield",
                flowError: flowError))
            
        default:
            // Most URLError have an English or technical message that is not
            // suitable for user display.
            return .present(ErrorPresentation(flowError: flowError))
        }
    }
}

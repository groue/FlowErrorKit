import Foundation

/// Handles `POSIXError`.
struct POSIXErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? POSIXError else {
            return .pass(flowError)
        }
        
        // The errors below are meaningful to the user, whatever the failed
        // operation. But the message of a POSIXError is only partially
        // localized, such as "The operation couldn’t be completed. No space
        // left on device". Reuse the localized message of the equivalent
        // CocoaError instead.
        switch error.code {
        case .ENOSPC, // "No space left on device"
                .EDQUOT: // "Disc quota exceeded"
            // "The file couldn’t be saved because there isn’t enough space."
            return .present(ErrorPresentation(
                flowError: flowError,
                title: CocoaError(.fileWriteOutOfSpace).localizedDescription))
            
        case .EROFS: // "Read-only file system"
            // "The file couldn’t be saved because the volume is read only."
            return .present(ErrorPresentation(
                flowError: flowError,
                title: CocoaError(.fileWriteVolumeReadOnly).localizedDescription))
            
        default:
            return .pass(flowError)
        }
    }
}

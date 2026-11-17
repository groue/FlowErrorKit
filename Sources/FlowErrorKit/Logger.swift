import Foundation
import os.log

/// The logger that records all flow errors presented with
/// `presentError(_:with:)`, before error handlers are invoked.
public let flowErrorLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FlowError")

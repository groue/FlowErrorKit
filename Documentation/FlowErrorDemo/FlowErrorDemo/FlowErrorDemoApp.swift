import Foundation
import SwiftUI

@main
struct FlowErrorDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemosNavigationView()
        }
    }
}

/// A convenience method for throwing errors.
///
/// - Parameters:
///   - error: The thrown error.
///   - failureProbability: The probability that the error is thrown.
///
/// - Returns: A random emoji.
///
/// - Throws: No error, or `error`, depending on `failureProbability`.
func randomEmoji(
    throwing error: @autoclosure () -> Error,
    failureProbability: Double)
throws -> String {
    if Double.random(in: 0...1) <= failureProbability {
        throw error()
    }
    
    return [
        "🙂",
        "😁",
        "😅",
        "😜",
        "🤓",
        "😡",
        "😨",
        "😵",
        "😬",
        "🤯",
        "🎃",
        "👻",
        "😈",
        "👍",
        "👎",
        "🤞",
        "🌼",
        "🐛",
        "🍀",
        "💣",
        "💥",
        "🌈",
        "❤️",
        "⚠️",
        "🎲",
        "🎶",
    ].randomElement()!
}

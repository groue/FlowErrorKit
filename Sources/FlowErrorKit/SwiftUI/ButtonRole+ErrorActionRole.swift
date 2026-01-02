import SwiftUI

extension ButtonRole {
    public init(role: ErrorActionRole) {
        switch role {
        case .destructive:
            self = .destructive
        }
    }
}

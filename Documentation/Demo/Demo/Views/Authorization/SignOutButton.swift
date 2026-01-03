import SwiftUI

struct SignOutButton: View {
    @Environment(\.signOut) var signOut
    
    var body: some View {
        Button("Sign Out") { signOut() }
    }
}

import SwiftUI
import MapKit

struct MainView: SignedInView {
    @State var camera = MapCameraPosition.automatic
    
    func body(session: Session) -> some View {
        Map(position: $camera) {
            UserAnnotation()
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            ToolbarItem(placement: .bottomBar) {
                MapUserLocationButton(position: $camera)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainView().environment(\.session, Session())
}

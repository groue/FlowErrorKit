import SwiftUI
import MapKit

struct MainView: SignedInView {
    @State var camera = MapCameraPosition.automatic
    
    func body(session: Session) -> some View {
        VStack {
            Map(position: $camera) {
                UserAnnotation()
            }
            MapUserLocationButton(position: $camera)
        }
    }
}

// MARK: - Preview

#Preview {
    MainView().environment(\.session, Session())
}

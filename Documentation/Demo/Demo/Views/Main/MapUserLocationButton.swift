import CoreLocation
import FlowErrorKit
import MapKit
import Observation
import SwiftUI

struct MapUserLocationButton: View {
    private enum PositionState {
        case idle
        case locating
        case followsUserLocation
    }
    
    @Binding private var position: MapCameraPosition
    @State private var viewModel = MapUserLocationButtonViewModel()
    @State private var state = PositionState.idle
    @State private var flowError: FlowError?
    
    init(position: Binding<MapCameraPosition>) {
        self._position = position
    }
    
    var body: some View {
        Button {
            toggleCameraPosition()
        } label: {
            if state == .locating {
                ProgressView()
            } else {
                Image(systemName: state == .idle ? "location" : "location.fill")
            }
        }
        .allowsHitTesting(state != .locating)
        .onChange(of: position, initial: true) {
            if state != .locating {
                updateStateFromPosition()
            }
        }
        .presentError($flowError, with: .alert)
        .handleError(with: viewModel)
    }
    
    private func toggleCameraPosition() {
        if position.followsUserLocation {
            position = .automatic
        } else {
            Task { await locateUser() }
        }
    }
    
    private func updateStateFromPosition() {
        if position.followsUserLocation {
            state = .followsUserLocation
        } else {
            state = .idle
        }
    }
    
    private func locateUser() async {
        do {
            state = .locating
            defer {
                updateStateFromPosition()
            }
            
            try await viewModel.locateUser()
            withAnimation {
                position = .userLocation(followsHeading: false, fallback: .automatic)
            }
        } catch {
            flowError = FlowError(error: error)
        }
    }
}

final class MapUserLocationButtonViewModel: NSObject {
    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<Void, Error>?
    private var isRequestingAuthorization = false
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
    
    func locateUser() async throws {
        try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManagerDidChangeAuthorization(locationManager)
        }
    }
}

extension MapUserLocationButtonViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if locationContinuation == nil {
            // Ignore authorization status change until we care about it.
            return
        }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isRequestingAuthorization = false
            locationManager.requestLocation()
            
        case .notDetermined:
            isRequestingAuthorization = true
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            if isRequestingAuthorization {
                isRequestingAuthorization = false
                if let locationContinuation {
                    self.locationContinuation = nil
                    locationContinuation.resume(throwing: CancellationError())
                }
            } else if let locationContinuation {
                self.locationContinuation = nil
                locationContinuation.resume(throwing: CLError(.denied))
            }
            
        @unknown default:
            isRequestingAuthorization = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationContinuation {
            self.locationContinuation = nil
            locationContinuation.resume()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        if let locationContinuation {
            self.locationContinuation = nil
            locationContinuation.resume(throwing: error)
        }
    }
}

extension MapUserLocationButtonViewModel: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        if flowError.error is CancellationError {
            // User has denied authorization when requested.
            return .cancel
            
        } else if let error = flowError.error as? CLError {
            switch error {
            case CLError.denied:
                // Denied error is not recoverable: drop the retry action, and
                // let the user grant the required permissions.
                let presentedFlowError = flowError
                    .droppingRetryAction()
                    .appendingAction("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                
                return .present(ErrorPresentation(
                    title: "Permission Required",
                    message: "Please grant access to your location in the Settings application.",
                    flowError: presentedFlowError))
                
            case CLError.geocodeCanceled:
                // Don't present this error
                return .cancel
                
            default:
                return .present(ErrorPresentation(
                    title: error.localizedDescription,
                    flowError: flowError))
            }
            
        } else {
            return .pass(flowError)
        }
    }
}

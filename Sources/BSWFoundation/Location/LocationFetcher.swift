//
//  Created by Pierluigi Cifani on 20/04/16.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
//

import Foundation
import CoreLocation

/**
 Simple wrapper that allows you to obtain the current location.
 
 Using it is as simple as:
 
 ```
 let currentLocation = try await LocationFetcher.fetcher.fetchCurrentLocation()
 ```
*/
@MainActor
public final class LocationFetcher: NSObject, CLLocationManagerDelegate {
    
    public enum LocationErrors: Swift.Error {
        case authorizationDenied
        case unknown
    }
    
    public static let fetcher = LocationFetcher()
    
    internal var locationManager = CLLocationManager()
    private var continuations: [CheckedContinuation<CLLocation, Error>] = []
    public let desiredAccuracy = kCLLocationAccuracyHundredMeters
    public var lastKnownLocation: CLLocation?

    override init() {
        super.init()
        
        guard let _ = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") as? String else {
            fatalError("Please add a NSLocationWhenInUseUsageDescription entry to your Info.plist")
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
    }

    public func fetchCurrentLocation(_ useCachedLocationIfAvailable: Bool = true) async throws -> CLLocation {
        if let lastKnownLocation = self.lastKnownLocation , useCachedLocationIfAvailable {
            return lastKnownLocation
        }
        
        if !self.continuations.isEmpty {
            return try await withCheckedThrowingContinuation({ continuation in
                self.continuations.append(continuation)
            })
        }

        switch locationManager.authorizationStatus {
        case .restricted:
            fallthrough
        case .denied:
            throw LocationErrors.authorizationDenied
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            throw LocationErrors.unknown
        }
        
        return try await withCheckedThrowingContinuation({ continuation in
            continuations.append(continuation)
        })
    }
    
    private func completeCurrentRequest(_ result: Swift.Result<CLLocation, LocationErrors> = .failure(.unknown)) {
        continuations.forEach({
            switch result {
            case .failure(let error):
                $0.resume(throwing: error)
            case .success(let location):
                $0.resume(returning: location)
            }
        })
        continuations = []
    }

    //MARK:- CLLocationManagerDelegate
    
    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            if let location = locations.first {
                self.lastKnownLocation = location
                completeCurrentRequest(.success(location))
            }
        }
    }
    
    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error finding location: \(error.localizedDescription)")
        MainActor.assumeIsolated {
            completeCurrentRequest()
        }
    }
    
    public nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    
        guard status != .notDetermined else { return }
        
        let isStatusAuthorized: Bool = {
            #if os(macOS)
            return (status == .authorizedAlways)
            #else
            return (status == .authorizedAlways || status == .authorizedWhenInUse)
            #endif
        }()
        if isStatusAuthorized {
            manager.requestLocation()
        } else {
            MainActor.assumeIsolated {
                completeCurrentRequest()
            }
        }
    }
}

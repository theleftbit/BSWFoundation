//
//  Created by Pierluigi Cifani on 20/04/16.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
//

import Foundation
import CoreLocation
import Deferred

#if os(iOS)

@available(iOS 9, *)
public final class LocationFetcher: NSObject, CLLocationManagerDelegate {
    
    public static let fetcher = LocationFetcher()
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var currentRequest: Deferred<CLLocation?>?
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
    
    public func fetchCurrentLocation(_ useCachedLocationIfAvailable: Bool = true) -> Future<CLLocation?> {
        if let lastKnownLocation = self.lastKnownLocation , useCachedLocationIfAvailable {
            return Future(value: lastKnownLocation)
        }
        
        if let currentRequest = self.currentRequest {
            return Future(currentRequest)
        }

        switch CLLocationManager.authorizationStatus() {
        case .restricted:
            fallthrough
        case .denied:
            return Future(value: nil)
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        }
        
        let deferredLocation = Deferred<CLLocation?>()
        self.currentRequest = deferredLocation
        return Future(deferredLocation)
    }
    
    private func completeCurrentRequest(_ location: CLLocation? = nil) {
        self.currentRequest?.fill(with: location)
        self.currentRequest = nil
    }

    //MARK:- CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.lastKnownLocation = location
            completeCurrentRequest(location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error finding location: \(error.localizedDescription)")
        completeCurrentRequest()
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    
        guard status != .notDetermined else { return }
        
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
        } else {
            completeCurrentRequest()
        }
    }

}
    
#endif

//
//  Created by Pierluigi Cifani on 20/04/16.
//  Copyright (c) 2016 Blurred Software SL. All rights reserved.
//

import Foundation
import CoreLocation
import Deferred

@available(iOS 9, *)
public class LocationFetcher: NSObject, CLLocationManagerDelegate {
    
    public static let fetcher = LocationFetcher()
    
    private let locationManager = CLLocationManager()
    private var lastKnownLocation: CLLocation?
    private var currentRequest: Deferred<CLLocation?>?
    public let desiredAccuracy = kCLLocationAccuracyHundredMeters
    
    override init() {
        super.init()
        
        guard let _ = NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationWhenInUseUsageDescription") as? String else {
            fatalError("Please add a NSLocationWhenInUseUsageDescription entry to your Info.plist")
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
    }
    
    public func fetchCurrentLocation(useCachedLocationIfAvailable: Bool = true) -> Future<CLLocation?> {
        if let lastKnownLocation = self.lastKnownLocation where useCachedLocationIfAvailable {
            return Future(value: lastKnownLocation)
        }
        
        if let currentRequest = self.currentRequest {
            return Future(currentRequest)
        }

        switch CLLocationManager.authorizationStatus() {
        case .Restricted:
            fallthrough
        case .Denied:
            return Future(value: nil)
        case .AuthorizedAlways:
            fallthrough
        case .AuthorizedWhenInUse:
            locationManager.requestLocation()
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        }
        
        let deferredLocation = Deferred<CLLocation?>()
        self.currentRequest = deferredLocation
        return Future(deferredLocation)
    }
    
    private func completeCurrentRequest(location: CLLocation? = nil) {
        self.currentRequest?.fill(location)
        self.currentRequest = nil
    }

    //MARK:- CLLocationManagerDelegate
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.lastKnownLocation = location
            completeCurrentRequest(location)
        }
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error finding location: \(error.localizedDescription)")
        completeCurrentRequest()
    }
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    
        guard status != .NotDetermined else { return }
        
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            manager.requestLocation()
        } else {
            completeCurrentRequest()
        }
    }

}

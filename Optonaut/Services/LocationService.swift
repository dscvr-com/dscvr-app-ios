//
//  Location.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/19/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveCocoa

typealias Coordinate = (latitude: Double, longitude: Double)

class LocationService: NSObject {
    
    private static let sharedInstance = LocationService()
    
    private let locationManager = CLLocationManager()
    private var callback: (Coordinate -> ())?
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    static func location() -> SignalProducer<Coordinate, NSError> {
        return SignalProducer { sink, disposable in
            sharedInstance.locationManager.startUpdatingLocation()
            sharedInstance.callback = { coordinate in
                sendNext(sink, coordinate)
                sendCompleted(sink)
                self.sharedInstance.locationManager.stopUpdatingLocation()
            }
            disposable.addDisposable {
                self.sharedInstance.locationManager.stopUpdatingLocation()
            }
        }
    }
    
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = Double(location.coordinate.latitude)
            let longitude = Double(location.coordinate.longitude)
            callback?((latitude, longitude))
        }
    }
    
}

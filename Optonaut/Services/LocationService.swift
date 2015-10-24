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
    
    private override init() {
        super.init()
        
        locationManager.delegate = self
    }
    
    static var enabled: Bool {
        return CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == .AuthorizedAlways
    }
    
    static func askPermission() {
        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            sharedInstance.locationManager.requestWhenInUseAuthorization()
        case .Denied:
            UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
        default: ()
        }
    }
    
    static func location() -> SignalProducer<Coordinate, NSError> {
        return SignalProducer { sink, disposable in
            
            sharedInstance.callback = { coordinate in
                sink.sendNext(coordinate)
                sink.sendCompleted()
                self.sharedInstance.locationManager.stopUpdatingLocation()
            }
            
            sharedInstance.locationManager.startUpdatingLocation()
            
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

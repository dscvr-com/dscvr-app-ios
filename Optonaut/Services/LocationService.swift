//
//  Location.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/19/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveSwift

typealias Coordinate = (latitude: Double, longitude: Double)

class LocationService: NSObject {
    
    fileprivate static let sharedInstance = LocationService()
    
    fileprivate var lastCoordinate: Coordinate?
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var callback: ((Coordinate) -> ())?
    
    fileprivate override init() {
        super.init()
        
        locationManager.delegate = self
    }
    
    static var enabled: Bool {
        return CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    static func lastLocation() -> Coordinate? {
        return sharedInstance.lastCoordinate
    }
    
    static func askPermission() {
        if !CLLocationManager.locationServicesEnabled() {
            sharedInstance.locationManager.requestWhenInUseAuthorization()
            return
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            sharedInstance.locationManager.requestWhenInUseAuthorization()
        case .denied:
            UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
        default: ()
        }
    }
    
    static func location() -> SignalProducer<Coordinate, NSError> {
        return SignalProducer { sink, disposable in
            
            sharedInstance.callback = { coordinate in
                sink.send(value: coordinate)
                sink.sendCompleted()
                self.sharedInstance.locationManager.stopUpdatingLocation()
            }
            
            sharedInstance.locationManager.startUpdatingLocation()
            
            disposable.add {
                self.sharedInstance.locationManager.stopUpdatingLocation()
            }
        }
    }
    
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = Double(location.coordinate.latitude)
            let longitude = Double(location.coordinate.longitude)
            let coords = (latitude, longitude)
            lastCoordinate = coords
            callback?(coords)
        }
    }
    
}

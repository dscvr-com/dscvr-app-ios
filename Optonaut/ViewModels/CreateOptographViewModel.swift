//
//  CreateOptographViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreLocation
import ObjectMapper

class CreateOptographViewModel: NSObject {
    
    let locationManager = CLLocationManager()
    
    let previewUrl = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    let latitude = MutableProperty<Float>(0)
    let longitude = MutableProperty<Float>(0)
    let description_ = MutableProperty<String>("")
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
            
    }
    
    func post() -> SignalProducer<Optograph, NSError> {
        let parameters = [
            "description": description_.value,
            "location": [
                "latitude": latitude.value,
                "longitude": longitude.value,
            ]
        ]
        
        let signalProducer = Api.post("optographs", authorized: true, parameters: parameters as? [String : AnyObject])
            .map { Mapper<Optograph>().map($0)! }
        
        return signalProducer
    }
}

// MARK: - CLLocationManagerDelegate
extension CreateOptographViewModel: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat = Float(location.coordinate.latitude)
            let lon = Float(location.coordinate.longitude)
            latitude.value = lat
            longitude.value = lon
            let parameters = [
                "latitude": lat,
                "longitude": lon,
            ]
            Api.post("locations/lookup", authorized: true, parameters: parameters)
                .map { json in Mapper<LocationMappable>().map(json)! }
                .start(next: { locationData in
                    self.location.value = locationData.description
                    self.locationManager.stopUpdatingLocation()
                })
        }
    }
    
}

private struct LocationMappable: Mappable {
    var description = ""
    
    private static func newInstance() -> Mappable {
        return LocationMappable()
    }
    
    mutating func mapping(map: Map) {
        description   <- map["description"]
    }
}
//
//  BLEService.swift
//  Orbit 360 Facetracking
//
//  Created by Philipp Meyer on 17.10.16.
//  Copyright © 2016 Philipp Meyer. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

// Services & Characteristics UUIDs
class BLEService: NSObject, CBPeripheralDelegate {
    let p: CBPeripheral
    let onServiceConnected: (CBService) -> Void
    let bleService: CBUUID
    let bleCharacteristic: CBUUID
    
    init(initWithPeripheral peripheral: CBPeripheral, onServiceConnected: (CBService) -> Void, bleService: CBUUID, bleCharacteristic: CBUUID) {
        self.onServiceConnected = onServiceConnected
        
        self.p = peripheral
        self.bleService = bleService
        self.bleCharacteristic = bleCharacteristic
        
        super.init()
        
        self.p.delegate = self
    }
    
    func startDiscoveringServices() {
        if p.services != nil {
            self.peripheral(p, didDiscoverServices: nil)
        } else {
            self.p.delegate = self
            self.p.discoverServices(nil)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        let uuidsForBTService: [CBUUID] = [bleCharacteristic]
        
        if (peripheral != self.p) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            // No Services
            return
        }
        
        for service in peripheral.services! {
            if service.UUID == bleService {
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service as CBService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if (peripheral != self.p) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }

        for characteristic in service.characteristics! {
            if characteristic.UUID == bleCharacteristic {
                onServiceConnected(service)
            }
        }
    }
}

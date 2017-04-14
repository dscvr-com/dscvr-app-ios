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
    
    init(initWithPeripheral peripheral: CBPeripheral, onServiceConnected: @escaping (CBService) -> Void, bleService: CBUUID, bleCharacteristic: CBUUID) {
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
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
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
            if service.uuid == bleService {
                peripheral.discoverCharacteristics(uuidsForBTService, for: service as CBService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (peripheral != self.p) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }

        for characteristic in service.characteristics! {
            if characteristic.uuid == bleCharacteristic {
                onServiceConnected(service)
            }
        }
    }
}

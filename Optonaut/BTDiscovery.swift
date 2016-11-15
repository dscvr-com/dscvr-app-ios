//
//  BTDiscovery.swift
//  DSCVR
//
//  Created by robert john alkuino on 11/15/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import CoreBluetooth

let btDiscoverySharedInstance = BTDiscovery();
var devicesName:[CBPeripheral] = []

class BTDiscovery: NSObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager?
    private var peripheralBLE: CBPeripheral?
    
    override init() {
        super.init()
        
        let centralQueue = dispatch_queue_create("com.raywenderlich", DISPATCH_QUEUE_SERIAL)
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    func startScanning() {
        if let central = centralManager {
            //central.scanForPeripheralsWithServices([BLEServiceUUID], options: nil)
            central.scanForPeripheralsWithServices(nil, options: nil)
            
        }
    }
    
    func devicesNameList() -> [CBPeripheral] {
        return devicesName
    }
    
    var bleService: BTService? {
        didSet {
            if let service = self.bleService {
                service.startDiscoveringServices()
            }
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        // Be sure to retain the peripheral or it will fail during connection.
        
        print("peripheralname\(peripheral.name)")
        
        // Validate peripheral information
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        } else {
            if !devicesName.contains(peripheral) {
                devicesName.append(peripheral)
            }
        }
        
        /*// If not already connected to a peripheral, then connect to this one
         if ((self.peripheralBLE == nil) || (self.peripheralBLE?.state == CBPeripheralState.Disconnected)) {
         // Retain the peripheral before trying to connect
         self.peripheralBLE = peripheral
         
         // Reset service
         self.bleService = nil
         
         // Connect to peripheral
         central.connectPeripheral(peripheral, options: nil)
         }*/
    }
    
    func connectToPeripheral(deviceName:CBPeripheral) {
        if let central = centralManager {
            self.peripheralBLE = deviceName
            self.bleService = nil
            central.connectPeripheral(deviceName, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        // Create new service class
        if (peripheral == self.peripheralBLE) {
            self.bleService = BTService(initWithPeripheral: peripheral)
        }
        
        // Stop scanning for new devices
        central.stopScan()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        // See if it was our peripheral that disconnected
        if (peripheral == self.peripheralBLE) {
            self.bleService = nil;
            self.peripheralBLE = nil;
        }
        
        // Start scanning for new devices
        self.startScanning()
    }
    
    // MARK: - Private
    
    func clearDevices() {
        self.bleService = nil
        self.peripheralBLE = nil
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
        case CBCentralManagerState.PoweredOff:
            self.clearDevices()
            
        case CBCentralManagerState.Unauthorized:
            // Indicate to user that the iOS device does not support BLE.
            break
            
        case CBCentralManagerState.Unknown:
            // Wait for another event
            break
            
        case CBCentralManagerState.PoweredOn:
            self.startScanning()
            
        case CBCentralManagerState.Resetting:
            self.clearDevices()
            
        case CBCentralManagerState.Unsupported:
            break
        }
    }
    
}
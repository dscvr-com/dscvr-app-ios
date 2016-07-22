//
//  BTService.swift
//  Optonaut
//
//  Created by Marc Andres on 22/03/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */
//let BLEServiceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
//let PositionCharUUID = CBUUID(string: "0000fff6-0000-1000-8000-00805f9b34fb")
let BLEServiceUUID = CBUUID(string: "00001000-0000-1000-8000-00805f9b34fb")
let PositionCharUUID = CBUUID(string: "00001001-0000-1000-8000-00805f9b34fb")
let ResponseCharUUID = CBUUID(string: "00001002-0000-1000-8000-00805f9b34fb")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

<<<<<<< HEAD
=======
protocol ResponseDataRequestDelegate {
    func responseData(data: NSData) -> NSData
}



>>>>>>> 79fb2656f36b786d4db45b72d8d0aef4db764364

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var positionCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([BLEServiceUUID])
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Mark: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        let uuidsForBTService: [CBUUID] = [PositionCharUUID, ResponseCharUUID]
        
        if (peripheral != self.peripheral) {
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
            print("service.UUID \(service.UUID)")
            if service.UUID == BLEServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service)
            }
        }
    }
    
    func peripheral( peripheral: CBPeripheral,
                      didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                                                       error: NSError?) {
        
        let responseData = characteristic.value
        print("reponsse data2 \(responseData)") 
        
        
        let bData = BService.sharedInstance
        bData.bluetoothData = responseData!
    }

    
    
    func peripheral( peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Got update from bluetooth \(characteristic.UUID)")
        peripheral.readValueForCharacteristic(characteristic)
        let responseData = characteristic.value
        print("reponsse data \(responseData)")
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("characteristic.UUID \(characteristic.UUID)")
                
                 if characteristic.UUID == PositionCharUUID {
                    self.positionCharacteristic = (characteristic)
                     self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                }
                
                if  characteristic.UUID == ResponseCharUUID {
                    
                    
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    
                    
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                   
                }
            }
        }
    }
    
    // Mark: - Private
    
    func writePosition(position: UInt8) {
        // See if characteristic has been discovered before writing to it
        if let positionCharacteristic = self.positionCharacteristic {
            // Need a mutable var to pass to writeValue function
            //var positionValue = position
            
            let stringServiceCommand = "fe01000201ffffffffffffffffffffffffffffff"
            //
            
            let length = stringServiceCommand.characters.count
            
            
            let rawData = UnsafeMutablePointer<CUnsignedChar>.alloc(length/2)
            var rawIndex = 0
            
            for var index = 0; index < length; index+=2{
                let single = NSMutableString()
                single.appendString(stringServiceCommand.substringWithRange(Range(start:stringServiceCommand.startIndex.advancedBy(index), end:stringServiceCommand.startIndex.advancedBy(index+2))))
                rawData[rawIndex] = UInt8(single as String, radix:16)!
                rawIndex++
            }
            
            let data1:NSData = NSData(bytes: rawData, length: length/2)
            rawData.dealloc(length/2)
            
            //
            //let data = NSData(bytes: &positionValue, length: sizeof(UInt8))
            self.peripheral?.writeValue(data1, forCharacteristic: positionCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        }
    }
    func sendCommand(stringServiceCommand:String) {
        // See if characteristic has been discovered before writing to it
        if let positionCharacteristic = self.positionCharacteristic {
            // Need a mutable var to pass to writeValue function
            
            let length = stringServiceCommand.characters.count
            
            
            let rawData = UnsafeMutablePointer<CUnsignedChar>.alloc(length/2)
            var rawIndex = 0
            
            for var index = 0; index < length; index+=2{
                let single = NSMutableString()
                single.appendString(stringServiceCommand.substringWithRange(Range(start:stringServiceCommand.startIndex.advancedBy(index), end:stringServiceCommand.startIndex.advancedBy(index+2))))
                rawData[rawIndex] = UInt8(single as String, radix:16)!
                rawIndex++
            }
            
            let data1:NSData = NSData(bytes: rawData, length: length/2)
            rawData.dealloc(length/2)
            
            //
            //let data = NSData(bytes: &positionValue, length: sizeof(UInt8))
            self.peripheral?.writeValue(data1, forCharacteristic: positionCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        }
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
}
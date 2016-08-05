//
//  BTService.swift
//  Optonaut
//
//  Created by Marc Andres on 22/03/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import CoreBluetooth
import SwiftyUserDefaults

/* Services & Characteristics UUIDs */
//let BLEServiceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
//let PositionCharUUID = CBUUID(string: "0000fff6-0000-1000-8000-00805f9b34fb")
let BLEServiceUUID = CBUUID(string: "00001000-0000-1000-8000-00805f9b34fb")
let PositionCharUUID = CBUUID(string: "00001001-0000-1000-8000-00805f9b34fb")
let ResponseCharUUID = CBUUID(string: "00001002-0000-1000-8000-00805f9b34fb")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"





//BLE#0x44A6E503892F


protocol ResponseDataRequestDelegate {
    func responseData(data: NSData) -> NSData
}

 

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var positionCharacteristic: CBCharacteristic?
    var ringFlag = 0 //  0 =  center; 1 =top ; 2 bot
    var motorFlag = 0
    
    
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
        
        let responseData = characteristic.value //<- notification
        print("reponsse data2 \(responseData)")
        
        let responseValue = hexString(responseData!)
        
    if Defaults[.SessionUseMultiRing]{
        
        if responseValue != "" {
        
        let index = responseValue.startIndex.advancedBy(14)
        responseValue[index] // returns Character 'o'
        
        let endIndex = responseValue.endIndex.advancedBy(-12)
        responseValue[Range(index ..< endIndex)] //<- ydirection
        responseValue.substringFromIndex(index)  //index till the endofString
        
        print("RP>>>>" + responseValue[Range(index ..< endIndex)]) //strip data -> for ydirection
            
            
        let index2 = responseValue.startIndex.advancedBy(23)
        let endIndex2 = responseValue.endIndex.advancedBy(-4)
        responseValue[Range(index2 ..< endIndex2)] //time elapsed
            
        var timelapsed = responseValue[Range(index2 ..< endIndex2)]
        
        print("TP>>>>" + responseValue[Range(index2 ..< endIndex2)])
            
        var yDirection = responseValue[Range(index ..< endIndex)]
        
            let bData = BService.sharedInstance
            print("ydirection",yDirection)
            // need to get the response value = get the current position
        
            // strip data - get the ydirection data
            if ringFlag == 0 {
                if motorFlag == 0 {
                               //"ffffee99" <- our motor
                    // Y is on center
                  //sendCommand("fe07020000081f012c005bffffffffffff") //move to top command
                    sendCommand("fe0702000007bc012c00f7ffffffffffff") //move to top command v2
                    //sendCommand("fe0702fffff9f7012c0022ffffffffffff") // top_ring
                    print("blecommanddone")
                    bData.dataHasCome.value = false
                    motorFlag = 1
                    
                    
                }else if motorFlag == 1 {
                                    // "ffffe890"
                    print("got2topring")
                    bData.dataHasCome.value = true
                    // not sure if this is the return data for the top
                   sendCommand("fe070100003be302bf00e5ffffffffffff") // josepeh's motor //rotate the motor x
                 //sendCommand("fe070100001c20014a008dffffffffffff") //<- our version
                    
                    motorFlag = 2
                    ringFlag = 1
                }
         
            } else if ringFlag == 1 {
                if motorFlag == 2 {
                              // "ffffe890"
                    // Y is on top
                    bData.dataHasCome.value = false
                  //sendCommand("fe0702ffffefc2012c00e3ffffffffffff") //move to bot command joseph's motor
                    sendCommand("fe0702fffff025012c0047ffffffffffff") //move to bot command joseph's motor v2
                    
                     //sendCommand("fe070200000c12012c0052ffffffffffff") // bot_ring
                    motorFlag = 3
                    
                }else if motorFlag == 3 {
                                    // "fffff4a2"
                    
                    // not sure if this is the return data for the bot
                    bData.dataHasCome.value = true
                    sendCommand("fe070100003be302bf00e5ffffffffffff"); // josepeh's motor //rotate the motor x
                    //sendCommand("fe070100001c20014a008dffffffffffff") //<- our version
                    ringFlag = 2
                    motorFlag = 4
                }

         
            } else if ringFlag == 2 {
         
                if motorFlag == 4 {
                             //  "fffff4a2"
                    bData.dataHasCome.value = false
                    motorFlag = 5
                    // Y is on bot
                   sendCommand("fe07020000081f012c005bffffffffffff") //move to top command                     sendCommand("fe0702fffff9f7012c0022ffffffffffff") // top_ring
                }else if motorFlag == 5  {
                                     //"ffffee99" <- our motor
                    // not sure if this is the return data for the bot
                    bData.dataHasCome.value = false
                    ringFlag = 3 // means done
                    motorFlag = 6
                }

            }
            
           
            bData.bluetoothData = responseData!
            bData.ydirection = yDirection
            bData.timelapsed = timelapsed
            
            
            
            
        }
        
        }
        
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
    
    
    //hextostring
    func hexString(data:NSData)->String{
        if data.length > 0 {
            let  hexChars = Array("0123456789abcdef".utf8) as [UInt8];
            let buf = UnsafeBufferPointer<UInt8>(start: UnsafePointer(data.bytes), count: data.length);
            var output = [UInt8](count: data.length*2 + 1, repeatedValue: 0);
            var ix:Int = 0;
            for b in buf {
                let hi  = Int((b & 0xf0) >> 4);
                let low = Int(b & 0x0f);
                output[ix++] = hexChars[ hi];
                output[ix++] = hexChars[low];
            }
            let result = String.fromCString(UnsafePointer(output))!;
            return result;
        }
        return "";
    }
    
    
}





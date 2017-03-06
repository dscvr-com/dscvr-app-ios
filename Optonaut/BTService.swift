//
//  BTService.swift
//  DSCVR
//
//  Created by robert john alkuino on 11/15/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import CoreBluetooth
import SwiftyUserDefaults

/* Services & Characteristics UUIDs */
//let BLEServiceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
//let PositionCharUUID = CBUUID(string: "0000fff6-0000-1000-8000-00805f9b34fb")
/*
let BLEServiceUUID = CBUUID(string: "00001000-0000-1000-8000-00805f9b34fb")
let PositionCharUUID = CBUUID(string: "00001001-0000-1000-8000-00805f9b34fb")
let ResponseCharUUID = CBUUID(string: "00001002-0000-1000-8000-00805f9b34fb")
*/
// new motor feb 14, 2017

let BLEServiceUUID = CBUUID(string: "69400001-B5A3-F393-E0A9-E50E24DCCA99")
let PositionCharUUID = CBUUID(string: "69400002-B5A3-F393-E0A9-E50E24DCCA99")
let ResponseCharUUID = CBUUID(string: "69400003-B5A3-F393-E0A9-E50E24DCCA99")




let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

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
        
        print("did connect with peripheral")
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        
        // test the computations
        //print("computeTopRotation \(self.computeTopRotation())")
        ringFlag = 0
        motorFlag = 0
        
        
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
       // self.peripheral?.discoverServices([BLEServiceUUID])

        self.peripheral?.discoverServices(nil)
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        ringFlag = 0
        motorFlag = 0
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Mark: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        let uuidsForBTService: [CBUUID] = [PositionCharUUID, ResponseCharUUID]
        
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            print("wrong peripheral")
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            // No Services
            print("No services")
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
       
        
        
        let responseValue = hexString(responseData!)
        print("responseData  \(responseData)")
        print("responseValue  \(responseValue)")
        if responseValue == "00" {
            return
        }
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
                
                let timelapsed = responseValue[Range(index2 ..< endIndex2)]
                
                print("TP>>>>" + responseValue[Range(index2 ..< endIndex2)])
                
                let yDirection = responseValue[Range(index ..< endIndex)]
                
                let bData = BService.sharedInstance
                print("ydirection",yDirection)
                // need to get the response value = get the current position
                
                // strip  data - get the ydirection data
                if ringFlag == 0 {
                    if motorFlag == 0 {
                        //"ffffee99" <- our motor
                        // Y is on center
                        bData.dataHasCome.value = false
                        // go to top
                        moveY(Int32(Defaults[.SessionTopCount]!), speed: Int32(Defaults[.SessionPPS]!))
                        //sendCommand("fe0702fffff9f7012c0022ffffffffffff") // top_ring
                        print("blecommanddone")
                        
                        motorFlag = 1
                        
                        
                    }else if motorFlag == 1 {
                        // "ffffe890"
                        print("got2topring")
                        //sendCommand("fe070100003be30276009cffffffffffff"); // rotate josepeh's motor v2
                        //sendCommand("fe070100001c20014a008dffffffffffff") //<- our version
                        
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue()) {
                            
                            print("1moveX \(Defaults[.SessionRotateCount])")
                            print("2moveX \(Defaults[.SessionPPS])")
                            print("1moveX \(Defaults[.SessionRotateCount]!)")
                            print("2moveX \(Defaults[.SessionPPS]!)")
                            self.moveX(Int32(Defaults[.SessionRotateCount]!), speed: Int32(Defaults[.SessionPPS]!))
                            //self.moveX(Int32(200), speed: Int32(1000))
                            bData.dataHasCome.value = true
                        }
                        
                        
                        
                        
                        motorFlag = 2
                        ringFlag = 1
                    }
                    
                } else if ringFlag == 1 {
                    if motorFlag == 2 {
                        // "ffffe890"
                        // Y is on top
                        bData.dataHasCome.value = false
                        // go to bottom
                        moveY(Int32(Defaults[.SessionBotCount]!), speed: Int32(Defaults[.SessionPPS]!))
                        
                        //sendCommand("fe070200000c12012c0052ffffffffffff") // bot_ring
                        motorFlag = 3
                        
                    }else if motorFlag == 3 {
                        // "fffff4a2"
                        //sendCommand("fe070100003be302bf00e5ffffffffffff"); // josepeh's motor //rotate the motor x
                        // sendCommand("fe070100003be30276009cffffffffffff"); // rotate josepeh's motor v2
                        
                        
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue()) {
                            print("3moveX \(Defaults[.SessionRotateCount])")
                            print("4moveX \(Defaults[.SessionPPS])")
                            print("3moveX \(Defaults[.SessionRotateCount]!)")
                            print("4moveX \(Defaults[.SessionPPS]!)")
                            //self.moveX(Int32(200), speed: Int32(250))
                            self.moveX(Int32(Defaults[.SessionRotateCount]!), speed: Int32(Defaults[.SessionPPS]!))
                            bData.dataHasCome.value = true
                        }
                        //sendCommand("fe070100001c20014a008dffffffffffff") //<- our version
                        ringFlag = 2
                        motorFlag = 4
                    }
                    
                    
                } else if ringFlag == 2 {
                    
                    if motorFlag == 4 {
                        //  "fffff4a2"
                        bData.dataHasCome.value = false
                        //sendCommand(self.computeTopRotation());
                        
                        moveY(Int32(Defaults[.SessionTopCount]!), speed: Int32(Defaults[.SessionPPS]!))
                        // Y is on bot
                        //sendCommand("fe07020000081f012c005bffffffffffff") //move to top command                     sendCommand("fe0702fffff9f7012c0022ffffffffffff") // top_ring
                        
                        motorFlag = 5
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
       print("didDiscoverCharacteristicsForService")
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            print("Wrong Peripheral")
            return
        }
        
        if (error != nil) {
            print("didDiscoverCharacteristicsForService  error")
            return
        }
        
        
        if let characteristics = service.characteristics {
            
            for characteristic in characteristics {
                print("characteristic.UUID \(characteristic.UUID)")
                
                if characteristic.UUID == PositionCharUUID {
                    print("position characteristic")
                    self.positionCharacteristic = (characteristic)
                    self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                }
                
                if  characteristic.UUID == ResponseCharUUID {
                    
                    print("response characteristic")
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    
                    
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                    
                }
            }
        }
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
    
    func toUint(signed: Int) -> UInt {
        
        let unsigned = signed >= 0 ?
            UInt(signed) :
            UInt(signed  - Int.min) + UInt(Int.max) + 1
        
        return unsigned
    }
    
    func checkSum(data: NSData) -> Int {
        let b = UnsafeBufferPointer<UInt8>(start:
            UnsafePointer(data.bytes), count: data.length)
        
        var sum = 0
        for i in 0..<data.length {
            sum += Int(b[i])
        }
        return sum & 0xff
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
    
    
    
    
    // ejoebstl code
    
    func sendCommand(opCode: UInt8, data: [UInt8]) {
        var command : [UInt8] = [0xFE]
        let lengthOfData = UInt8(data.count)
        command.append(lengthOfData)
        command.append(opCode)
        command.appendContentsOf(data)
        
        var checksum = UInt32(0)
        for c in command {
            checksum += UInt32(c)
        }
        
        let crc = UInt8(checksum & 0xFF)
        command.append(crc)
        //append 
        for _ in 1...9 {
            command.append(UInt8(0xFF))
        }
        
        
        let Data = NSMutableData(bytes: command, length: command.count)
        if let positionCharacteristic = self.positionCharacteristic {
            // Need a mutable var to pass to writeValue function
            
            print ("penn - > sending data \(Data)")
            print ("penn - > sending positionCharacteristic \(command.count)")
            //let data = NSData(bytes: &positionValue, length: sizeof(UInt8))
            self.peripheral?.writeValue(Data, forCharacteristic: positionCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        }
        
       
    }
    
    func moveX(steps: Int32, speed: Int32) {
        var command = toByteArray(steps)
        command = command.reverse()
        command.append(UInt8((speed >> 8) & 0xFF))
        command.append(UInt8(speed & 0xFF))
        command.append(0x00) //Fullstep if <500 halfstep?
        sendCommand(0x01, data: command)
    }
    
    func moveY(steps: Int32, speed: Int32) {
        var command = toByteArray(steps)
        command = command.reverse()
        command.append(UInt8((speed >> 8) & 0xFF))
        command.append(UInt8(speed & 0xFF))
        command.append(0x00)
        sendCommand(0x02, data: command)
    }
    
    func moveXandY(stepsX: Int32, speedX: Int32, stepsY: Int32, speedY: Int32) {
        var command = toByteArray(stepsX)
        command = command.reverse()
        command.append(UInt8((speedX >> 8) & 0xFF))
        command.append(UInt8(speedX & 0xFF))
        var commandYpart = toByteArray(stepsY)
        commandYpart = commandYpart.reverse()
        commandYpart.append(UInt8((speedY >> 8) & 0xFF))
        commandYpart.append(UInt8(speedY & 0xFF))
        commandYpart.append(0x00)
        command.appendContentsOf(commandYpart)
        sendCommand(0x03, data: command)
    }
    
    func sendStop() {
        sendCommand(0x04, data: [])
    }
    
    func toByteArray<T>(var value: T) -> [UInt8] {
        return withUnsafePointer(&value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
        }
    }
    
    
    
    
}
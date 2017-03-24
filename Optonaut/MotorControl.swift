//
//  MotorControl.swift
//  Orbit 360 Facetracking
//
//  Created by Philipp Meyer on 24.10.16.
//  Copyright © 2016 Philipp Meyer. All rights reserved.
//

import Foundation
import CoreBluetooth

class MotorControl: NSObject, CBPeripheralDelegate {
    var service : CBService
    var peripheral : CBPeripheral
    
    var positionInitialized: Bool
    var motorPositionX: Int
    var motorPositionY: Int

    let allowCommandInterrupt: Bool
    var executing: Bool
    
    static let BLEServiceUUID =                CBUUID(string: "69400001-B5A3-F393-E0A9-E50E24DCCA99")
    static let BLECharacteristicUUID =         CBUUID(string: "69400002-B5A3-F393-E0A9-E50E24DCCA99")
    static let BLECharacteristicResponseUUID = CBUUID(string: "69400003-B5A3-F393-E0A9-E50E24DCCA99")
    
    init(s: CBService, p: CBPeripheral, allowCommandInterrupt: Bool) {
        self.service = s
        self.peripheral = p
        self.motorPositionX = 0
        self.motorPositionY = 0
        self.positionInitialized = false
        self.allowCommandInterrupt = allowCommandInterrupt
        self.executing = false
        super.init()
        for characteristic in service.characteristics! {
            if characteristic.UUID == MotorControl.BLECharacteristicResponseUUID {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
            }
        }
        peripheral.delegate = self
    }

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
        
        let Data = NSMutableData(bytes: command, length: command.count)
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            // check for data characteristic
            if thisCharacteristic.UUID == MotorControl.BLECharacteristicUUID {
                self.peripheral.writeValue(Data, forCharacteristic: thisCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
            }
        }
    }
    
    func moveX(steps: Int32, speed: Int32) {
        var command = toByteArray(steps)
        command = command.reverse()
        command.append(UInt8((speed >> 8) & 0xFF))
        command.append(UInt8(speed & 0xFF))
        command.append(0x00)
        sendCommand(0x01, data: command)
        self.executing = true
    }
    
    func moveY(steps: Int32, speed: Int32) {
        var command = toByteArray(steps)
        command = command.reverse()
        command.append(UInt8((speed >> 8) & 0xFF))
        command.append(UInt8(speed & 0xFF))
        command.append(0x00)
        sendCommand(0x02, data: command)
        self.executing = true
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
        self.executing = true
    }

    func sendStop() {
        sendCommand(0x04, data: [])
        self.executing = true
    }
    
    func toByteArray<T>(var value: T) -> [UInt8] {
        return withUnsafePointer(&value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
        }
    }
    
    
    func fromByteArray<T>(value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBufferPointer {
            return UnsafePointer<T>($0.baseAddress).memory
        }
    }
    
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if characteristic.UUID.isEqual(MotorControl.BLECharacteristicResponseUUID) {
            let data = characteristic.value
            let numberOfBytes = data?.length
            
            // TODO: Check if this is actually the move command. 
            if (numberOfBytes != 20) {
                print("Error on BLE notification: Received \(numberOfBytes) bytes instead of 20.")
                return
            }
            
            var byteArray = [UInt8](count: numberOfBytes!, repeatedValue: 0)
            data?.getBytes(&byteArray, length: numberOfBytes!)
            
            motorPositionX = fromByteArray([byteArray[10], byteArray[9], byteArray[8], byteArray[7]], Int.self)
            motorPositionY = fromByteArray([byteArray[6], byteArray[5], byteArray[4], byteArray[3]], Int.self)
            
            print("Received update from motor. x: \(motorPositionX), y: \(motorPositionY)")
            self.executing = false
        }
    }
}

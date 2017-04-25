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
    static let topButton =    "FE01080108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
    static let bottomButton = "FE01080007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"


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
            if characteristic.uuid == MotorControl.BLECharacteristicResponseUUID {
                peripheral.setNotifyValue(true, for: characteristic as CBCharacteristic)
            }
        }
        peripheral.delegate = self
    }

    func sendCommand(_ opCode: UInt8, data: [UInt8]) {
        var command : [UInt8] = [0xFE]
        let lengthOfData = UInt8(data.count)
        command.append(lengthOfData)
        command.append(opCode)
        command.append(contentsOf: data)

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
            if thisCharacteristic.uuid == MotorControl.BLECharacteristicUUID {
                self.peripheral.writeValue(Data as Data, for: thisCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }

    func moveX(_ steps: Int32, speed: Int32) {
        var command = toByteArray(steps)
        command = command.reversed()
        command.append(UInt8((speed >> 8) & 0xFF))
        command.append(UInt8(speed & 0xFF))
        command.append(0x00)
        sendCommand(0x01, data: command)
        self.executing = true
    }

    func moveY(_ steps: Int32, speed: Int32) {
        var command = toByteArray(steps)
        command = command.reversed()
        command.append(UInt8((speed >> 8) & 0xFF))
        command.append(UInt8(speed & 0xFF))
        command.append(0x00)
        sendCommand(0x02, data: command)
        self.executing = true
    }

    func moveXandY(_ stepsX: Int32, speedX: Int32, stepsY: Int32, speedY: Int32) {
        var command = toByteArray(stepsX)
        command = command.reversed()
        command.append(UInt8((speedX >> 8) & 0xFF))
        command.append(UInt8(speedX & 0xFF))
        var commandYpart = toByteArray(stepsY)
        commandYpart = commandYpart.reversed()
        commandYpart.append(UInt8((speedY >> 8) & 0xFF))
        commandYpart.append(UInt8(speedY & 0xFF))
        commandYpart.append(0x00)
        command.append(contentsOf: commandYpart)
        sendCommand(0x03, data: command)
        self.executing = true
    }

    func sendStop() {
        sendCommand(0x04, data: [])
        self.executing = true
    }

    func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafePointer(to: &value) {
            Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size)) as Any
            } as! [UInt8]
    }


    func fromByteArray<T>(_ value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBufferPointer {
            return UnsafeRawPointer($0.baseAddress!).load(as: T.self)
        }
    }


    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid.isEqual(MotorControl.BLECharacteristicResponseUUID) {
            let data = characteristic.value
            let numberOfBytes = data!.count

            if (numberOfBytes != 20) {
                print("Error on BLE notification: Received \(numberOfBytes) bytes instead of 20.")
                return
            }

            var byteArray = [UInt8](repeating: 0, count: numberOfBytes)
            (data as NSData?)?.getBytes(&byteArray, length: numberOfBytes)

            let str = byteArray.reduce("", { $0 + String(format: "%02x", $1)})
            print(str)

            if (str.uppercased() == MotorControl.topButton) {
                print("top")
                return
            }
            if (str.uppercased() == MotorControl.bottomButton) {
                print("bottom")
                return
            }

            motorPositionX = fromByteArray([byteArray[10], byteArray[9], byteArray[8], byteArray[7]], Int.self)
            motorPositionY = fromByteArray([byteArray[6], byteArray[5], byteArray[4], byteArray[3]], Int.self)

            print("Received update from motor. x: \(motorPositionX), y: \(motorPositionY)")
            self.executing = false
        }
    }
}

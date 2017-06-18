//
//  MotorControl.swift
//  Orbit 360 Facetracking
//
//  Created by Philipp Meyer on 24.10.16.
//  Copyright © 2016 Philipp Meyer. All rights reserved.
//

import Foundation
import CoreBluetooth

struct MotorCommand {
    
    init(_dest: Point, _speed: Point, _sleep: Int = 0) {
        self.destination = _dest
        self.speed = _speed
        self.sleep = _sleep
    }
    
    let destination: Point // In Radiants
    let speed: Point // In steps/second
    let sleep: Int
}

class MotorControl: NSObject, CBPeripheralDelegate, RotationMatrixSource {
    var service : CBService
    var peripheral : CBPeripheral

    var positionInitialized: Bool
    var startTime = CFAbsoluteTimeGetCurrent()
    
    static let motorStepsX = 5111
    static let motorStepsY = 17820

    var currentScript = [MotorCommand]()
    
    // Positions in RADIANTS
    var startPosition = Point(x: 0, y: -(.pi / 2))
    var moved = Point(x: 0, y: 0)
    var currentPosition = Point(x: 0, y: -(.pi / 2))
    
    // Speed in RADS/SEC
    var speed = Point(x: 1, y: 1)
    // Command in RADIANTS
    var command = Point(x: 0, y: 0)
    
    var sleep: Int = 0

    let allowCommandInterrupt: Bool
    var executing: Bool

    static let BLEServiceUUID =                CBUUID(string: "69400001-B5A3-F393-E0A9-E50E24DCCA99")
    static let BLECharacteristicUUID =         CBUUID(string: "69400002-B5A3-F393-E0A9-E50E24DCCA99")
    static let BLECharacteristicResponseUUID = CBUUID(string: "69400003-B5A3-F393-E0A9-E50E24DCCA99")
    static let topButton =    "FE01080108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
    static let bottomButton = "FE01080007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"

    // This function is polled
    func getRotationMatrix() -> GLKMatrix4 {
        let currentPosition = updateAngles()
        
        let diff = pabs(p: moved - command)
        let eps = Float(0.000001)
        
        if(diff.x < eps && diff.y < eps && currentScript.count > 0) {
            sleep = sleep - 1
            startPosition = currentPosition
            command = Point(x: 0, y: 0)
            if(sleep <= 0) {
                execNextCommand()
            }
        }
        
        print("Phi: \(currentPosition.x)     Theta: \(currentPosition.y)")
        return phiThetaToRotationMatrix(currentPosition.x, theta: currentPosition.y)
    }
    
    private func execNextCommand() {
        let nextCommand = currentScript.remove(at: 0)
        sleep = nextCommand.sleep
        moveXandYRadiants(radsX: nextCommand.destination.x, speedX: Int32(nextCommand.speed.x), radsY: nextCommand.destination.y, speedY: Int32(nextCommand.speed.y))
    }
    
    func runScript(script: [MotorCommand]) {
        assert(currentScript.count == 0)
        
        currentScript = script
        execNextCommand()
    }
    
    func stepsToRadiantsX(steps: Int32) -> Float {
        return Float(steps) / Float(MotorControl.motorStepsX) * Float(M_PI * 2)
    }
    
    func radiantsToStepsX(rads: Float) -> Int32 {
        return Int32(rads / Float(M_PI * 2) * Float(MotorControl.motorStepsX))
    }
    
    func stepsToRadiantsY(steps: Int32) -> Float {
        return Float(steps) / Float(MotorControl.motorStepsY) * Float(M_PI * 2)
    }
    
    func radiantsToStepsY(rads: Float) -> Int32 {
        return Int32(rads / Float(M_PI * 2) * Float(MotorControl.motorStepsY))
    }

    func updateAngles() -> Point {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let timediff = currentTime - startTime
        
        moved = pmin(a: pabs(p: speed * Float(timediff)), b: pabs(p: command)) // Vector we moved so far.
        moved = Point(x: moved.x * sign(command.x), y: moved.y * sign(command.y))
        
        currentPosition = moved + startPosition
        
        return currentPosition
    }

    init(s: CBService, p: CBPeripheral, allowCommandInterrupt: Bool) {
        self.service = s
        self.peripheral = p
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
    
    func moveXRadiants(rads: Float, speed: Int32) {
        startPosition = currentPosition
        self.speed = Point(x: stepsToRadiantsX(steps: speed), y: 1)
        command = Point(x: rads, y: 0)
        startTime = CFAbsoluteTimeGetCurrent()
        moveX(-radiantsToStepsX(rads: rads), speed: speed)
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
    
    func moveYRadiants(rads: Float, speed: Int32) {
        startPosition = currentPosition
        self.speed = Point(x: 1, y: stepsToRadiantsY(steps: speed))
        command = Point(x: 0, y: rads)
        startTime = CFAbsoluteTimeGetCurrent()
        moveY(-radiantsToStepsY(rads: rads), speed: speed)
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
    
    func moveXandYRadiants(radsX: Float, speedX: Int32, radsY: Float, speedY: Int32) {
        startPosition = currentPosition
        speed = Point(x: stepsToRadiantsX(steps: speedX), y: stepsToRadiantsY(steps: speedY))
        command = Point(x: radsX, y: radsY)
        startTime = CFAbsoluteTimeGetCurrent()
        let stepsX = radiantsToStepsX(rads: radsX)
        let stepsY = radiantsToStepsY(rads: radsY)
        moveXandY(-stepsX, speedX: speedX, stepsY: -stepsY, speedY: speedY)
    }

    func moveXandY(_ stepsX: Int32, speedX: Int32, stepsY: Int32, speedY: Int32) {
        if (stepsX == 0 && stepsY == 0) {
            return
        }
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
        return withUnsafeBytes(of: &value) { Array($0) }
    }

    func fromByteArray<T>(_ value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBytes {
            $0.baseAddress!.load(as: T.self)
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
                NotificationCenter.default.post(name: Notification.Name(rawValue: remoteManualNotificationKey), object: self, userInfo: nil)
                return
            }
            if (str.uppercased() == MotorControl.bottomButton) {
                print("bottom")
                NotificationCenter.default.post(name: Notification.Name(rawValue: remoteMotorNotificationKey), object: self, userInfo: nil)
                return
            }
        }
    }
}

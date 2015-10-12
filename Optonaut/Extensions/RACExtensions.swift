//
//  RACExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

extension SignalType {
    public func ignoreError() -> Signal<Value, NoError> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case .Error(_): break
                case let .Next(val): sendNext(observer, val)
                case .Completed: sendCompleted(observer)
                case .Interrupted: sendInterrupted(observer)
                }
            }
        }
    }
}
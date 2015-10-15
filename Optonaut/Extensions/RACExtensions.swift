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
    
    public func transformToBool() -> Signal<Bool, NoError> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case .Error(_): sendNext(observer, false)
                case .Next(_): break
                case .Completed: sendNext(observer, true)
                case .Interrupted: sendInterrupted(observer)
                }
            }
        }
    }
    
    public func completedAsNext() -> Signal<Void, Error> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case let .Error(err): sendError(observer, err)
                case .Next(_): break
                case .Completed: sendNext(observer, ())
                case .Interrupted: sendInterrupted(observer)
                }
            }
        }
    }
    
    public func nextAsCompleted() -> Signal<Void, Error> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case let .Error(err): sendError(observer, err)
                case .Next(_): sendCompleted(observer)
                case .Completed: sendCompleted(observer)
                case .Interrupted: sendInterrupted(observer)
                }
            }
        }
    }
}

public extension SignalType where Value: Equatable {
    public func equalsTo(value: Value) -> Signal<Bool, Error> {
        return map({ next in next == value })
    }
    
    public func filter(values: [Value]) -> Signal<Value, Error> {
        return filter({ value in values.indexOf { $0 == value } != nil })
    }
}

extension SignalProducerType {
    public func ignoreError() -> SignalProducer<Value, NoError> {
        return lift { $0.ignoreError() }
    }
    
    public func transformToBool() -> SignalProducer<Bool, NoError> {
        return lift { $0.transformToBool() }
    }
    
    public func completedAsNext() -> SignalProducer<Void, Error> {
        return lift { $0.completedAsNext() }
    }
    
    public func nextAsCompleted() -> SignalProducer<Void, Error> {
        return lift { $0.nextAsCompleted() }
    }
}

public extension SignalProducerType where Value: Equatable {
    public func equalsTo(value: Value) -> SignalProducer<Bool, Error> {
        return lift { $0.equalsTo(value) }
    }
    
    public func filter(values: [Value]) -> SignalProducer<Value, Error> {
        return lift { $0.filter(values) }
    }
}
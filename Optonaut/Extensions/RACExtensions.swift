//
//  RACExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

private let userInteractiveQueue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)

extension SignalType {
    public func ignoreError() -> Signal<Value, NoError> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case .Error(_): break
                case let .Next(val): observer.sendNext(val)
                case .Completed: observer.sendCompleted()
                case .Interrupted: observer.sendInterrupted()
                }
            }
        }
    }
    
    public func transformToBool() -> Signal<Bool, NoError> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case .Error(_): observer.sendNext(false)
                case .Next(_): break
                case .Completed: observer.sendNext(true)
                case .Interrupted: observer.sendInterrupted()
                }
            }
        }
    }
    
    public func completedAsNext() -> Signal<Void, Error> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case let .Error(err): observer.sendError(err)
                case .Next(_): break
                case .Completed: observer.sendNext(())
                case .Interrupted: observer.sendInterrupted()
                }
            }
        }
    }
    
    public func nextAsCompleted() -> Signal<Void, Error> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case let .Error(err): observer.sendError(err)
                case .Next(_): observer.sendCompleted()
                case .Completed: observer.sendCompleted()
                case .Interrupted: observer.sendInterrupted()
                }
            }
        }
    }
    
    public func observeOnUserInteractive() -> Signal<Value, Error> {
        return observeOn(QueueScheduler(queue: userInteractiveQueue))
    }
    
    public func observeOnMain() -> Signal<Value, Error> {
        return observeOn(UIScheduler())
    }
    
}
    
public extension SignalType where Value == Bool {
    
    public func mapToTuple<T>(right: T, _ wrong: T) -> Signal<T, Error> {
        return map { $0 ? right : wrong }
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
    
    public func startOnUserInteractive() -> SignalProducer<Value, Error> {
        return startOn(QueueScheduler(queue: userInteractiveQueue))
    }
    
    public func observeOnUserInteractive() -> SignalProducer<Value, Error> {
        return lift { $0.observeOnUserInteractive() }
    }
    
    public func startOnMain() -> SignalProducer<Value, Error> {
        return startOn(UIScheduler())
    }
    
    public func observeOnMain() -> SignalProducer<Value, Error> {
        return lift { $0.observeOnMain() }
    }
    
    public static func fromValues(values: [Value]) -> SignalProducer<Value, Error> {
        return SignalProducer { sink, _ in
            for value in values {
                sink.sendNext(value)
            }
            sink.sendCompleted()
        }
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
    
public extension SignalProducerType where Value == Bool {
    
    public func mapToTuple<T>(right: T, _ wrong: T) -> SignalProducer<T, Error> {
        return lift { $0.mapToTuple(right, wrong) }
    }
        
}
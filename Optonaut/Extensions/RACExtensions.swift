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
                case .Failed(_): break
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
                case .Failed(_): observer.sendNext(false)
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
                case let .Failed(err): observer.sendFailed(err)
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
                case let .Failed(err): observer.sendFailed(err)
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
    
    public func retryUntil(interval: NSTimeInterval, onScheduler scheduler: DateSchedulerType, fn: () -> Bool) -> Signal<Value, Error> {
        precondition(interval >= 0)
        
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .Failed, .Interrupted:
                    scheduler.schedule {
                        observer.action(event)
                    }
                    
                default:
                    var schedulerDisposable: Disposable?
                    var retryAttempts = 100
                    schedulerDisposable = scheduler.scheduleAfter(scheduler.currentDate, repeatingEvery: interval, withLeeway: interval) {
                        if fn() || --retryAttempts == 0 {
                            observer.action(event)
                            schedulerDisposable?.dispose()
                        }
                    }
                }
            }
        }
    }
    
    public func delayLatestUntil<E>(triggerSignal: Signal<Bool, E>) -> Signal<Value, Error> {
        let (newSignal, newObserver) = Signal<Value, Error>.pipe()
        
        var passOn = false
        var latestValue: Value?
        
        observe { event in
            if passOn {
                newObserver.action(event)
            } else if case .Next(let val) = event {
                latestValue = val
            }
        }
        
        triggerSignal.filter(identity).take(1).observeNext { _ in
            if let latestValue = latestValue {
                newObserver.sendNext(latestValue)
            }
            passOn = true
        }
        
        return newSignal
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
    
    public func retryUntil(interval: NSTimeInterval, onScheduler scheduler: DateSchedulerType, fn: () -> Bool) -> SignalProducer<Value, Error> {
        return lift { $0.retryUntil(interval, onScheduler: scheduler, fn: fn) }
    }
    
    public func delayLatestUntil<E>(triggerProducer: SignalProducer<Bool, E>) -> SignalProducer<Value, Error> {
        return liftRight(Signal.delayLatestUntil)(triggerProducer)
    }
    
    public static func fromValues(values: [Value]) -> SignalProducer<Value, Error> {
        return SignalProducer { sink, _ in
            for value in values {
                sink.sendNext(value)
            }
            sink.sendCompleted()
        }
    }
    
    /// Right-associative lifting of a binary signal operator over producers. That
    /// is, the argument producer will be started before the receiver. When both
    /// producers are synchronous this order can be important depending on the operator
    /// to generate correct results.
    @warn_unused_result(message="Did you forget to call `start` on the producer?")
    private func liftRight<U, F, V, G>(transform: Signal<Value, Error> -> Signal<U, F> -> Signal<V, G>) -> SignalProducer<U, F> -> SignalProducer<V, G> {
        return { otherProducer in
            return SignalProducer { observer, outerDisposable in
                self.startWithSignal { signal, disposable in
                    outerDisposable.addDisposable(disposable)
                    
                    otherProducer.startWithSignal { otherSignal, otherDisposable in
                        outerDisposable.addDisposable(otherDisposable)
                        
                        transform(signal)(otherSignal).observe(observer)
                    }
                }
            }
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
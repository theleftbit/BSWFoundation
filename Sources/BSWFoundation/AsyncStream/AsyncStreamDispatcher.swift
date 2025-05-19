//
//  Created by Michele Restuccia on 16/5/25.
//

import Foundation

public protocol AsyncStreamNamedEvent: Hashable & Sendable {
    associatedtype Name: Hashable & Sendable
    var name: Name { get }
}

public actor AsyncStreamDispatcher<Event: AsyncStreamNamedEvent> {
    
    public init() {}
    
    private var subscribers: [Event.Name: [UUID: AsyncStream<Event>.Continuation]] = [:]
    
    public func subscribe(to events: Set<Event.Name>) -> AsyncStream<Event> {
        let id = UUID()
        let (stream, continuation) = AsyncStream<Event>.makeStream(bufferingPolicy: .unbounded)
        
        for eventName in events {
            var subscriber: [UUID: AsyncStream<Event>.Continuation]
            if let _subscriber = subscribers[eventName] {
                subscriber = _subscriber
            } else {
                subscriber = [:]
            }
            subscriber[id] = continuation
            subscribers[eventName] = subscriber
        }
        
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeSubscriber(id, for: events)
            }
        }
        return stream
    }
    
    public func publish(_ event: Event) {
        let name = event.name
        for (_, continuation) in subscribers[name] ?? [:] {
            continuation.yield(event)
        }
    }
    
    private func removeSubscriber(_ id: UUID, for events: Set<Event.Name>) {
        for eventName in events {
            subscribers[eventName]?.removeValue(forKey: id)
            if subscribers[eventName]?.isEmpty == true {
                subscribers.removeValue(forKey: eventName)
            }
        }
    }
}

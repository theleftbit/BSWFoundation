//
//  Created by Michele Restuccia on 16/5/25.
//

import Foundation

/// Example usage:
///
/// ```swift
/// // 1. Define your event enum
/// enum NotificationEvent: NamedEvent, Hashable, Sendable {
///     case userLoggedIn(userID: String)
///
///     var name: Name {
///         switch self {
///         case .userLoggedIn: return .userLoggedIn
///         }
///     }
///
///     enum Name: Hashable, Sendable {
///         case userLoggedIn
///     }
///
///     static let userLoggedIn = CaseExtractor<NotificationEvent, String>(
///         name: .userLoggedIn,
///         match: {
///             guard case let .userLoggedIn(userID) = $0 else { return nil }
///             return userID
///         }
///     )
/// }
///
/// // 2. Your app should expose a shared `Current` instance containing a dispatcher:
/// @MainActor var Current: World
/// struct World {
///     let notifications = AsyncStreamDispatcher<NotificationEvent>()
/// }
///
/// // 3. Subscribe from anywhere (e.g. UIKit view controller)
/// Task {
///     let token = await Current.notifications.subscribe(NotificationEvent.userLoggedIn) { userID in
///         print("Logged in:", userID)
///     }
/// }
///
/// // 4. Publish from any part of the app
/// Current.notifications.publish(.userLoggedIn(userID: "abc123"))
/// ```

/// A protocol representing events that have a name used for filtering.
/// Used in combination with `AsyncStreamDispatcher` to create strongly-typed event systems.
public protocol AsyncStreamNamedEvent: Hashable & Sendable {
    associatedtype Name: Hashable & Sendable
    var name: Name { get }
}

public actor AsyncStreamDispatcher<Event: AsyncStreamNamedEvent> {

    private var subscribers: [Event.Name: [UUID: AsyncStream<Event>.Continuation]] = [:]
    
    public func subscribe(to event: Event.Name) -> AsyncStream<Event> {
        subscribe(to: [event])
    }
    
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

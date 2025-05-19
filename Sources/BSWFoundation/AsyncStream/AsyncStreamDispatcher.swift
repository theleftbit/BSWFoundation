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
public protocol NamedEvent: Hashable & Sendable {
    associatedtype Name: Hashable & Sendable
    var name: Name { get }
}

/// A type-safe, async alternative to `NotificationCenter` for dispatching named events across your app.
/// Subscribers receive values via `AsyncStream`, matched using a `CaseExtractor`.
/// Events are dispatched immediately to all active subscribers that match the event name.
/// - Note: This type is safe for concurrency by design, as it is implemented as an `actor`.
public actor AsyncStreamDispatcher<Event: NamedEvent> {

    public init() {}
    
    private var subscribers: [Event.Name: [UUID: AsyncStream<Event>.Continuation]] = [:]

    /// Publishes a new event to all active subscribers that match the event's name.
    /// - Parameter event: The event instance to publish.
    public func publish(_ event: Event) {
        subscribers[event.name]?.values.forEach { $0.yield(event) }
    }

    /// Subscribes to a specific event and receives values matched by the provided `CaseExtractor`.
    /// - Warning: Avoid capturing strong references (like `self`) inside the handler, especially from long-lived objects such as view models or UI elements. Use `[weak self]` or delegate to another component if needed.
    /// - Parameters:
    ///   - extractor: A `CaseExtractor` defining the event case to listen for.
    ///   - handler: A `@Sendable` closure that will be called when the event occurs.
    /// - Returns: A `SubscriptionToken` that can be used to cancel the subscription manually.
    /// - Important: Keep a strong reference to the returned token to maintain the subscription.
    ///              The subscription will automatically end when the token is deallocated.
    public func subscribe<T>(
        _ extractor: CaseExtractor<Event, T>,
        handler: @escaping @Sendable (T) -> Void
    ) -> SubscriptionToken {
        let id = UUID()
        let (stream, continuation) = subscribe(to: [extractor.name], id: id)
        let matcher = extractor.match

        let task = Task.detached {
            for await event in stream {
                if let value = matcher(event) {
                    handler(value)
                }
            }
        }
        return SubscriptionToken {
            continuation.finish()
            task.cancel()
            await self.removeSubscriber(id, for: [extractor.name])
        }
    }
}

// MARK: Extensions

private extension AsyncStreamDispatcher {

    /// Registers a subscriber to a given set of event names using a shared UUID.
    func subscribe(to names: Set<Event.Name>, id: UUID) -> (AsyncStream<Event>, AsyncStream<Event>.Continuation) {
        let (stream, continuation) = AsyncStream<Event>.makeStream(bufferingPolicy: .unbounded)

        for name in names {
            subscribers[name, default: [:]][id] = continuation
        }
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id, for: names) }
        }
        return (stream, continuation)
    }

    /// Removes a subscriber identified by the given UUID for all provided event names.
    func removeSubscriber(_ id: UUID, for names: Set<Event.Name>) {
        for name in names {
            subscribers[name]?.removeValue(forKey: id)
            if subscribers[name]?.isEmpty == true {
                subscribers.removeValue(forKey: name)
            }
        }
    }
}

// MARK: CaseExtractor

/// A utility that extracts a specific associated value from an enum case, used to filter events.
/// Typically created as a static constant in the event enum.
public struct CaseExtractor<Event: NamedEvent, Output>: Sendable {
    public let name: Event.Name
    public let match: @Sendable (Event) -> Output?

    public init(
        name: Event.Name,
        match: @escaping @Sendable (Event) -> Output?
    ) {
        self.name = name
        self.match = match
    }
}

// MARK: SubscriptionToken

/// A token representing an active event subscription.
/// Hold on to this token to keep the subscription alive.
/// Call `cancel()` to terminate the subscription early.
/// - Important: If the token is deallocated, the subscription will be automatically cancelled.
public class SubscriptionToken: @unchecked Sendable {
    private let cancelAction: @Sendable () async -> Void
    private var isCancelled = false

    init(cancel: @escaping @Sendable () async -> Void) {
        self.cancelAction = cancel
    }

    /// Cancels the subscription manually.
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        Task { await cancelAction() }
    }
}

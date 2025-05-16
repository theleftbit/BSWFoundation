//
//  Created by Michele Restuccia on 16/5/25.

import Foundation

/// Example usage:
///
/// ```swift
/// enum MyAppEvent: NamedEvent, Hashable, Sendable {
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
///     static let userLoggedIn = CaseExtractor<MyAppEvent, String>(
///         name: .userLoggedIn,
///         match: {
///             if case let .userLoggedIn(userID) = $0 { return userID }
///             return nil
///         }
///     )
/// }
///
/// let dispatcher = AsyncStreamDispatcher<MyAppEvent>()
///
/// dispatcher.subscribe(MyAppEvent.userLoggedIn) { userID in
///     print("🔐 Logged in:", userID)
/// }
///
/// dispatcher.publish(.userLoggedIn(userID: "abc123"))
/// ```

public protocol NamedEvent: Hashable & Sendable {
    associatedtype Name: Hashable & Sendable
    var name: Name { get }
}

public actor AsyncStreamDispatcher<Event: NamedEvent> {

    public init() {}

    private var subscribers: [Event.Name: [UUID: AsyncStream<Event>.Continuation]] = [:]

    public func publish(_ event: Event) {
        subscribers[event.name]?.values.forEach { $0.yield(event) }
    }

    public func subscribe<T>(
        _ extractor: CaseExtractor<Event, T>,
        handler: @escaping @Sendable (T) -> Void
    ) {
        let stream = subscribe(to: [extractor.name])
        let matcher = extractor.match
        
        Task.detached {
            for await event in stream {
                if let value = matcher(event) {
                    handler(value)
                }
            }
        }
    }
}

// MARK: Extensions

private extension AsyncStreamDispatcher {

    func subscribe(to names: Set<Event.Name>) -> AsyncStream<Event> {
        let id = UUID()
        let (stream, continuation) = AsyncStream<Event>.makeStream(bufferingPolicy: .unbounded)
        
        for name in names {
            subscribers[name, default: [:]][id] = continuation
        }
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id, for: names) }
        }
        return stream
    }

    private func removeSubscriber(_ id: UUID, for names: Set<Event.Name>) {
        for name in names {
            subscribers[name]?.removeValue(forKey: id)
            if subscribers[name]?.isEmpty == true {
                subscribers.removeValue(forKey: name)
            }
        }
    }
}

// MARK: CaseExtractor

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

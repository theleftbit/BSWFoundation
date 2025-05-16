//
//  Created by Michele Restuccia on 16/5/25.

import Foundation

/// Example usage:
///
/// ```swift
/// struct MyAppAsyncEvent {
///     enum Name: Hashable, Sendable {
///         case userLoggedIn
///     }
///
///     enum Event: Hashable, Sendable {
///         case userLoggedIn(userID: String)
///     }
///
///     static let userLoggedIn = CaseExtractor<Name, Event, String>(
///         name: .userLoggedIn,
///         match: {
///             if case let .userLoggedIn(userID) = $0 { return userID }
///             return nil
///         }
///     )
/// }
///
/// let dispatcher = AsyncStreamDispatcher<MyAppAsyncEvent.Name, MyAppAsyncEvent.Event>()
///
/// await dispatcher.subscribe(MyAppAsyncEvent.userLoggedIn) { userID in
///     print("🔐 Logged in:", userID)
/// }
///
/// await dispatcher.publish(.userLoggedIn(userID: "abc123"), name: .userLoggedIn)
/// ```

public actor AsyncStreamDispatcher<Name: Hashable & Sendable, Event: Sendable & Hashable> {

    public init() {}

    private var subscribers: [Name: [UUID: AsyncStream<Event>.Continuation]] = [:]

    public func publish(_ event: Event, name: Name) {
        subscribers[name]?.values.forEach { $0.yield(event) }
    }

    public func subscribe<T>(
        _ extractor: CaseExtractor<Name, Event, T>,
        handler: @escaping @Sendable (T) async -> Void
    ) {
        let stream = subscribe(to: [extractor.name])
        let matcher = extractor.match

        Task.detached {
            for await event in stream {
                if let value = matcher(event) {
                    await handler(value)
                }
            }
        }
    }
}

// MARK: Extensions

private extension AsyncStreamDispatcher {

    func subscribe(to names: Set<Name>) -> AsyncStream<Event> {
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

    private func removeSubscriber(_ id: UUID, for names: Set<Name>) {
        for name in names {
            subscribers[name]?.removeValue(forKey: id)
            if subscribers[name]?.isEmpty == true {
                subscribers.removeValue(forKey: name)
            }
        }
    }
}

// MARK: CaseExtractor

public struct CaseExtractor<Name: Hashable & Sendable, Event, Output>: Sendable {
    public let name: Name
    public let match: @Sendable (Event) -> Output?

    public init(
        name: Name,
        match: @escaping @Sendable (Event) -> Output?
    ) {
        self.name = name
        self.match = match
    }
}

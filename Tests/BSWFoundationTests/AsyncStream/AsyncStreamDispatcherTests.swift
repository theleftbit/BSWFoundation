//
//  Created by Michele Restuccia on 16/5/25.
//

import Foundation
import Testing
@testable import BSWFoundation

enum MyAppEvent: NamedEvent, Hashable, Sendable {
    case sendValue(value: Int)
    case sendVoid
    
    var name: Name {
        switch self {
        case .sendValue: return .sendValue
        case .sendVoid: return .sendVoid
        }
    }
    
    enum Name: Hashable, Sendable {
        case sendValue
        case sendVoid
    }
}

// MARK: Tests

struct AsyncStreamDispatcherTests {

    @Test
    func test_sendValue_event_is_received() async throws {
        let dispatcher = AsyncStreamDispatcher<MyAppEvent>()
        let box = SyncBox<Int?>(nil)

        await dispatcher.subscribe(MyAppEvent.sendValueExtractor) { value in
            box.set(value)
        }
        await dispatcher.publish(.sendValue(value: 42))
        try await Task.sleep(nanoseconds: 50_000_000) // allow delivery
        #expect(box.get() == 42)
    }

    @Test
    func test_sendValue_event_is_filtered_out() async throws {
        let dispatcher = AsyncStreamDispatcher<MyAppEvent>()
        let box = SyncBox(false)

        await dispatcher.subscribe(MyAppEvent.sendValueExtractor) { _ in
            box.set(true)
        }
        await dispatcher.publish(.sendVoid)
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(!box.get())
    }

    @Test
    func test_sendVoid_event_is_received() async throws {
        let dispatcher = AsyncStreamDispatcher<MyAppEvent>()
        let box = SyncBox(false)

        await dispatcher.subscribe(MyAppEvent.sendVoidExtractor) {
            box.set(true)
        }
        await dispatcher.publish(.sendVoid)
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(box.get())
    }

    @Test
    func test_sendVoid_event_is_filtered_out() async throws {
        let dispatcher = AsyncStreamDispatcher<MyAppEvent>()
        let box = SyncBox(false)

        await dispatcher.subscribe(MyAppEvent.sendVoidExtractor) {
            box.set(true)
        }
        await dispatcher.publish(.sendValue(value: 99))
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(!box.get())
    }
}

// MARK: Extractors

private extension MyAppEvent {
    
    static var sendValueExtractor: CaseExtractor<MyAppEvent, Int> {
        .init(
            name: .sendValue,
            match: {
                guard case let .sendValue(value) = $0 else { return nil }
                return value
            }
        )
    }
    
    static var sendVoidExtractor: CaseExtractor<MyAppEvent, Void> {
        .init(
            name: .sendVoid,
            match: {
                guard case .sendVoid = $0 else { return nil }
                return ()
            }
        )
    }
}

// MARK: SyncBox, simple sync (non-actor) box for use with sync handlers

private class SyncBox<T: Sendable>: @unchecked Sendable {
    private var value: T
    private let queue = DispatchQueue(label: "SyncBox", attributes: .concurrent)

    init(_ value: T) {
        self.value = value
    }

    func set(_ newValue: T) {
        queue.async(flags: .barrier) {
            self.value = newValue
        }
    }

    func get() -> T {
        var result: T!
        queue.sync {
            result = self.value
        }
        return result
    }
}

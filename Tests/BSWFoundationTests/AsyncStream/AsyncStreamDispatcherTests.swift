//
//  Created by Michele Restuccia on 16/5/25.
//

import Foundation
import Testing
@testable import BSWFoundation

enum MyAppEvent: AsyncStreamNamedEvent, Hashable, Sendable {
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
        let sentEvent = MyAppEvent.sendValue(value: 42)
        Task.detached {
            await dispatcher.publish(sentEvent)
        }
        for await receivedEvent in await dispatcher.subscribe(to: .sendValue) {
            #expect(receivedEvent == sentEvent)
            break
        }
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

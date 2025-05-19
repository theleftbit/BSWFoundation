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
        Task.detached {
            await dispatcher.publish(.sendValue(value: 42))
        }
        for await event in await dispatcher.subscribe(to: .sendValue) {

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

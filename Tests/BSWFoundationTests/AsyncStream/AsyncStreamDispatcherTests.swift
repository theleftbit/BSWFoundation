//
//  Created by Michele Restuccia on 16/5/25.
//

import Foundation
import Testing
@testable import BSWFoundation

// MARK: Tests

struct AsyncStreamDispatcherTests {

    @Test
    func subscribeToEvents() async throws {
        let dispatcher = AsyncStreamDispatcher<MyAppEvent>()
        let sentEvent = MyAppEvent.sendValue(value: 42)
        Task.detached {
            await dispatcher.publish(sentEvent)
        }
        for await receivedEvent in await dispatcher.subscribe(to: [.sendValue]) {
            #expect(receivedEvent == sentEvent)
            break
        }
    }
    
    @Test(.disabled())
    func subscribeToSingleEvent() async throws {
        let dispatcher = AsyncStreamDispatcher<MyAppEvent>()
        let sentEvent = MyAppEvent.sendValue(value: 42)
        Task.detached {
            await dispatcher.publish(sentEvent)
        }
        var receivedEvent: MyAppEvent?
        let task = await dispatcher.subscribe(to: .sendValue, onEventReceived: { event in
            receivedEvent = sentEvent
            print("Receiving stuff")
        })
        try await Task.sleep(for: .seconds(1))
        print("When is this done?")
        task.cancel()
        try #expect(#require(receivedEvent) == sentEvent)
    }

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
}

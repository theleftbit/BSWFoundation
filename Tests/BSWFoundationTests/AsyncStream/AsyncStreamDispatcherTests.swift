//
//  Created by Michele Restuccia on 16/5/25.
//

import Foundation
import Testing
@testable import BSWFoundation

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

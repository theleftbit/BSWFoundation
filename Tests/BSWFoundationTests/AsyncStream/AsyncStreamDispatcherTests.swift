//
//  Created by Michele Restuccia on 16/5/25.
//

import Foundation
import Testing
@testable import BSWFoundation

struct AsyncStreamDispatcherTests {
    
    private let dispatcher: AsyncStreamDispatcher<Events>
    
    init() {
        dispatcher = AsyncStreamDispatcher<Events>()
    }
    
    @Test
    func subscribeToEvent() async throws {
        let expectedEvent = Events.sendValue(value: 42)
        let stream = await dispatcher.subscribe(to: [.sendValue])
        
        Task.detached {
            await dispatcher.publish(expectedEvent)
        }
        for await e in stream {
            #expect(e == expectedEvent)
            break
        }
    }
    
    @Test
    func subscribeToEventAndOtherEventsAreFilteredOut() async throws {
        let unexpectedEvent = Events.sendVoid
        let stream = await dispatcher.subscribe(to: [.sendValue])
        
        Task.detached {
            await dispatcher.publish(unexpectedEvent)
        }
        
        var didReceive = false
        let task = Task {
            for await _ in stream {
                didReceive = true
            }
        }
        try await Task.sleep(for: .seconds(2)) // Cancel this task to exit the test
        task.cancel()
        #expect(!didReceive)
    }
    
    @Test
    func multipleSubscribersReceiveSameEvent() async throws {
        let expectedEvent = Events.sendValue(value: 42)
        let stream1 = await dispatcher.subscribe(to: [.sendValue])
        let stream2 = await dispatcher.subscribe(to: [.sendValue])
        
        Task.detached {
            await dispatcher.publish(expectedEvent)
        }
        for await e in stream1 {
            #expect(e == expectedEvent)
            break
        }
        for await e in stream2 {
            #expect(e == expectedEvent)
            break
        }
    }
    
    // MARK: Events
    
    enum Events: AsyncStreamNamedEvent, Hashable, Sendable {
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

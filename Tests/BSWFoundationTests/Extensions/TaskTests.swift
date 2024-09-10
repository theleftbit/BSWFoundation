
import Testing
import BSWFoundation

struct TaskTests {
    
    @Test
    func never() async throws {
        await confirmation(expectedCount: 0) { confirmation in
            let task = Task(priority: .userInitiated) {
                let _ = try await Task.never
                confirmation()
            }
            task.cancel()
        }
    }
    
    @Test
    func neverFuncOverride() async throws {
        @Sendable func someThingThatReturnsAValue() async throws -> Int {
            try await Task.never()
        }
        
        await confirmation(expectedCount: 0) { confirmation in
            let task = Task(priority: .userInitiated) {
                let _ = try await someThingThatReturnsAValue()
                confirmation()
            }
            task.cancel()
        }
    }
}

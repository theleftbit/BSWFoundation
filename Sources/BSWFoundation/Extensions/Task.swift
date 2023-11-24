#if os(Android)
#else

import Foundation

public extension Task where Success == Never, Failure == Never {
    /// Returns a Task that will never return... Well, actually, it'll complete in 1000 seconds
    static var never: Void {
        get async throws {
            try await Task.sleep(nanoseconds: 1_000_000_000_000)
        }
    }
    
    /// Use this override to for your unimplemented functions
    static func never<T>() async throws -> T {
        let _ = try await _Concurrency.Task.never
        fatalError()
    }
}

#endif

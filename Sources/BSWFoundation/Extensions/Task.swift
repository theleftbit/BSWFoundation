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

public extension Task where Success == Void, Failure == CancellationError {

    struct ValueError: LocalizedError {
        public var errorDescription: String? {
            "Didn't receive asynchronous value."
        }
    }

    static func wait<T>(operation: @escaping () async throws -> T) throws -> T {
        var v: T? = nil
        AsyncWaiter({
            v = $0
        }, operation: operation).wait()

        if let v = v {
            return v
        } else {
            throw ValueError()
        }
    }
}

/// Wait for async operation to return value and call callback with the value
/// This class is intended to workaround/simplify async/await + actors isolation
/// https://twitter.com/krzyzanowskim/status/1523233140914876416
private class AsyncWaiter<T> {
    var didReceiveValue: Bool = false
    let value: (T) -> Void
    let operation: () async throws -> T

    init(_ value: @escaping (T) -> Void, operation: @escaping () async throws -> T) {
        self.value = value
        self.operation = operation
    }

    func wait() {
        Task.detached {
            do {
                self.value(try await self.operation())
                self.signal()
            } catch {
                self.signal()
                throw error
            }
        }

        while !didReceiveValue {
            RunLoop.current.run(mode: .default, before: .distantFuture)
        }
    }

    func signal() {
        didReceiveValue = true
    }
}

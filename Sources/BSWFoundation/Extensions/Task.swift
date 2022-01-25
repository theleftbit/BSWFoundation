
public extension Task where Success == Never, Failure == Never {
    /// Returns a Task that will never return... Well, actually, it'll complete in 1000 seconds
    static var never: Void {
        get async throws {
            try await Task.sleep(nanoseconds: 1_000_000_000_000)
        }
    }
}

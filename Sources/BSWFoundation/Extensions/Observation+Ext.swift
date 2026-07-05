import Foundation
import Observation

extension Observable where Self: AnyObject & Sendable {

    /// Bridges observation of `keyPath` into an `AsyncStream` that yields the current value and
    /// then every subsequent value when the observed property changes.
    public func stream<Value: Sendable>(
        for keyPath: KeyPath<Self, Value>
    ) -> AsyncStream<Value> {
        AsyncStream(Value.self) { continuation in
            let coordinator = ObservationStreamCoordinator(object: self, keyPath: keyPath, continuation: continuation)
            continuation.onTermination = { _ in coordinator.cancel() }
            coordinator.start()
        }
    }
}

/// Drives `withObservationTracking` for ``stream(for:)``, re-arming after each change *off the
/// current call stack* to avoid re-entrant registration. `DispatchQueue` is unavailable on wasm
/// (single-threaded), so there we reschedule with a `Task` (the JavaScriptKit event loop).
///
/// It is a class so the reschedule closure captures a `Sendable` `self` rather than a recursive
/// local function (which Swift 6's region-based isolation rejects as a `sending` data-race risk).
private final class ObservationStreamCoordinator<Root: AnyObject & Sendable, Value: Sendable>: @unchecked Sendable {
    private weak var object: Root?
    private let keyPath: KeyPath<Root, Value>
    private let continuation: AsyncStream<Value>.Continuation
    private var isCancelled = false

    init(object: Root, keyPath: KeyPath<Root, Value>, continuation: AsyncStream<Value>.Continuation) {
        self.object = object
        self.keyPath = keyPath
        self.continuation = continuation
    }

    func start() {
        track()
    }

    func cancel() {
        isCancelled = true
    }

    private func track() {
        withObservationTracking {
            guard let object, !isCancelled else { return }
            continuation.yield(object[keyPath: keyPath])
        } onChange: { [weak self] in
            self?.reschedule()
        }
    }

    private func reschedule() {
        guard !isCancelled else { return }
        #if os(WASI)
        Task { [weak self] in self?.track() }
        #else
        DispatchQueue.main.async { [weak self] in self?.track() }
        #endif
    }
}

extension AsyncStream where Element: Equatable {
  public func until(_ e: Element) async {
    var iterator = self.makeAsyncIterator()
    while let value = await iterator.next() {
      if e == value {
        return
      }
    }
  }
}

import Foundation
import Observation

#if !os(WASI)
// `stream(for:)` re-arms observation tracking via `DispatchQueue.main.async`, which is
// unavailable on wasm (single-threaded). A concurrency-correct wasm reschedule (via the
// JavaScriptKit event loop) is a follow-up; the helper is excluded on wasm for now.
extension Observable where Self: AnyObject & Sendable {

    public func stream<Value: Sendable>(
        for keyPath: KeyPath<Self, Value>
    ) -> AsyncStream<Value> {
        let box = ObservationBox()
        nonisolated(unsafe) let keyPath = keyPath

        return AsyncStream(Value.self) { continuation in
            @Sendable func track(object: Self) {
                Observation.withObservationTracking { [weak object] in
                    guard let self = object, !box.isCancelled else { return }
                    let value = self[keyPath: keyPath]
                    continuation.yield(value)
                } onChange: { [weak object] in
                    DispatchQueue.main.async {
                        guard let self = object, !box.isCancelled else { return }
                        track(object: self)
                    }
                }
            }

            continuation.onTermination = { _ in
                box.isCancelled = true
            }

            track(object: self)
        }
    }
}

private final class ObservationBox: @unchecked Sendable {
    var isCancelled = false
}
#endif

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

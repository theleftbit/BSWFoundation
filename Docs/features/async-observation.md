# Async Streams And Observation

This area bridges event-style state changes into `AsyncStream`.

## AsyncStreamDispatcher

`AsyncStreamDispatcher<Event>` is an actor that lets callers subscribe to named event sets and publish events by name.

Important behavior:

- Event names come from `AsyncStreamNamedEvent.Name`.
- Each subscription receives a buffering policy of `bufferingNewest(1)`.
- Subscribers are removed when their stream terminates.
- Publishing sends the event to current subscribers for that event name.

## Observation Stream

`Observable.stream(for:)` observes a key path and emits values through an `AsyncStream`.

The helper uses `Observation.withObservationTracking` and resubscribes on change. It is intended for lightweight observation flows where consuming code wants async iteration instead of callback state.

## Testing Notes

`AsyncStream.until(_:)` waits until an equatable element appears, which is useful for asynchronous tests.


import Testing
import Observation
import BSWFoundation

@Suite
struct ObservationTests {
    
    @Observable
    @MainActor
    final class ViewModel {
        var isReady: Bool = false
        var count: Int = 0
        var title: String = "Initial"

        func setIsReady() {
            isReady = true
        }
    }
    
    @MainActor
    @Test
    func itCompletesCorrectly() async throws {
        let viewModel = ViewModel()
        Task {
            try? await Task.sleep(for: .milliseconds(20))
            viewModel.setIsReady()
        }
        #expect(viewModel.isReady == false)
        await viewModel.stream(for: \.isReady).until(true)
        #expect(viewModel.isReady)
    }

    @MainActor
    @Test
    func streamImmediatelyYieldsCurrentValue() async throws {
        let viewModel = ViewModel()
        viewModel.count = 42

        var iterator = viewModel.stream(for: \.count).makeAsyncIterator()

        #expect(await iterator.next() == 42)
    }

    @MainActor
    @Test
    func streamYieldsSequentialChanges() async throws {
        let viewModel = ViewModel()
        var iterator = viewModel.stream(for: \.count).makeAsyncIterator()

        #expect(await iterator.next() == 0)

        viewModel.count = 1
        #expect(await iterator.next() == 1)

        viewModel.count = 2
        #expect(await iterator.next() == 2)

        viewModel.count = -1
        #expect(await iterator.next() == -1)
    }

    @MainActor
    @Test
    func changingUnobservedPropertyDoesNotYield() async throws {
        let viewModel = ViewModel()

        await confirmation(expectedCount: 1) { confirmation in
            let task = Task { @MainActor in
                for await _ in viewModel.stream(for: \.count) {
                    confirmation()
                }
            }

            try? await Task.sleep(for: .milliseconds(20))
            viewModel.title = "Changed"
            try? await Task.sleep(for: .milliseconds(20))
            task.cancel()
        }
    }

    @MainActor
    @Test
    func terminatingStreamStopsFurtherObservation() async throws {
        let viewModel = ViewModel()

        await confirmation(expectedCount: 2) { confirmation in
            let task = Task { @MainActor in
                for await value in viewModel.stream(for: \.count) {
                    confirmation()
                    if value == 1 {
                        break
                    }
                }
            }

            try? await Task.sleep(for: .milliseconds(20))
            viewModel.count = 1
            try? await Task.sleep(for: .milliseconds(20))
            viewModel.count = 2
            try? await Task.sleep(for: .milliseconds(20))
            task.cancel()
        }
    }

    @MainActor
    @Test
    func streamDoesNotRetainObservedObject() async throws {
        weak var weakViewModel: ViewModel?
        var stream: AsyncStream<Int>?

        do {
            let viewModel = ViewModel()
            weakViewModel = viewModel
            stream = viewModel.stream(for: \.count)
        }

        #expect(weakViewModel == nil)

        if var iterator = stream?.makeAsyncIterator() {
            #expect(await iterator.next() == 0)
        } else {
            Issue.record("Expected stream to exist")
        }
    }
}

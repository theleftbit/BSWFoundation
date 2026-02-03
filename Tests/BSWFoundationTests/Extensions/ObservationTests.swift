
import Testing
import Observation

@Suite
struct ObservationTests {
    
    @Observable
    @MainActor
    class ViewModel {
        var isReady: Bool = false
        func setIsReady() {
            isReady = true
        }
    }
    
    @MainActor
    @Test
    func itCompletesCorrectly() async throws {
        let viewModel = ViewModel()
        Task {
            try await Task.sleep(for: .milliseconds(20))
            viewModel.setIsReady()
        }
        #expect(viewModel.isReady == false)
        await viewModel.stream(for: \.isReady).until(true)
        #expect(viewModel.isReady)
    }
}

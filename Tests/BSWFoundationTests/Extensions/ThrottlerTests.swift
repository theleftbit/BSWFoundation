import Foundation
import BSWFoundation
import Testing

struct ThrottlerTests {
    
    @Test("The Throttler should only call the work function once every 0.5 seconds")
    func itWorks() async throws {
        let seconds: Double = 0.5
        let sut = Throttler(seconds: seconds)
        await confirmation(expectedCount: 1) { confirmation in
            sut.throttle { confirmation() }
            sut.throttle { confirmation() }
            sut.throttle { confirmation() }
            sut.throttle { confirmation() }
            try? await Task.sleep(for: .seconds(seconds + 0.1))
        }
    }
}

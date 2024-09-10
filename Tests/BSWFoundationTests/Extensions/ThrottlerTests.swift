import Foundation
import BSWFoundation
import Testing

struct ThrottlerTests {
    
    @available(iOS 16.0, *)
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
 
    /// The job of this test is to make sure that work sent to the Throttler is not executed immediatelly,
    /// but rather at least `maxInterval` is waited. In this test case, we want to check that nothing
    /// is executed because we're checking 10 milliseconds before `maxInterval` expires.
    @available(iOS 16.0, *)
    @Test
    func itDoesntJustSpitTheFirstJobButRatherWaitsForTheDelayToKickIn() async throws {
        let seconds: Double = 0.5
        await confirmation(expectedCount: 0) { confirmation in
            let sut = Throttler(seconds: seconds)
            sut.throttle { confirmation() }
            try? await Task.sleep(for: .seconds(seconds - 0.1))
        }
    }
}

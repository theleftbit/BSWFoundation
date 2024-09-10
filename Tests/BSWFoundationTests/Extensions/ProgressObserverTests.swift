import Foundation
import BSWFoundation
import Testing

struct ProgressObserverTests {
    
    @available(iOS 16.0, *)
    @Test
    func progressObserving() async throws {
        var sut: ProgressObserver!
        weak var weakSUT: ProgressObserver?

        await confirmation(expectedCount: 2) { confirmation in

            let progress = Progress(totalUnitCount: 2)
            progress.completedUnitCount = 0
            sut = ProgressObserver(progress: progress) {
                switch $0.completedUnitCount {
                case 1, 2:
                    confirmation()
                default:
                    Issue.record()
                }
            }
            weakSUT = sut
            progress.completedUnitCount = 1
            try? await Task.sleep(for: .milliseconds(10))
            progress.completedUnitCount = 2
            try? await Task.sleep(for: .milliseconds(10))
        }

        sut = nil

        #expect(weakSUT == nil) //This is to test that it is indeed dealloc
    }
}

#if canImport(Testing)

import Foundation
import Testing
@testable import BSWFoundation

@Suite
struct BundleTests {
    
    @Test
    func osName() async throws {
        #if os(macOS)
        #expect(Bundle.main.osName.contains("macOS"))
        #else
        #expect(Bundle.main.osName.contains("iOS"))
        #endif
    }
}
#endif

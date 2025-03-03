#if canImport(Testing)

import Foundation
import Testing
@testable import BSWFoundation

@Suite
struct BundleTests {
    
    @Test
    func osName() async throws {
        let name = Bundle.main.osName
        #if os(macOS)
        #expect(name.contains("macOS"))
        #elseif os(watchOS)
        #expect(name.contains("watchOS"))
        #else
        #expect(name.contains("iOS"))
        #endif
    }
}
#endif

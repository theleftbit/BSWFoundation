
import Task
import BSWFoundation
import XCTest

class DeferredTests: XCTestCase {    
    func testMappingFromTaskToSwiftConcurrency() async throws {
        let task: Task<Int> = JSONParser.parseData("29".data(using: .utf16)!)
        let value = try await task.toSwiftConcurrency()
        XCTAssert(value == 29)
    }
}

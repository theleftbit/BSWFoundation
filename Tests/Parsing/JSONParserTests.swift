//
//  Created by Pierluigi Cifani on 08/06/2017.
//

import XCTest
import BSWFoundation
import Deferred

class JSONParserTests: XCTestCase {

    struct SampleModel: Identifiable, Codable {
        let identity: Identity
        let name: String
        let amount: Double

        enum CodingKeys : String, CodingKey {
            case identity = "id", name, amount
        }
    }

    func testParsing() throws {
        let model = SampleModel(identity: "123456", name: "Hola", amount: 5678)
        let jsonData = try JSONEncoder().encode(model)
        let task: Task<SampleModel> = JSONParser.parseData(jsonData)

        let exp = expectation(description: "")
        task.upon(.main) { (result) in
            XCTAssert(result.value != nil)
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testArrayParsing() throws {
        let model1 = SampleModel(identity: "123456", name: "Hola", amount: 5678)
        let model2 = SampleModel(identity: "987642", name: "🍻", amount: 0986)
        let array = [model1, model2]
        let jsonData = try JSONEncoder().encode(array)

        let task: Task<[SampleModel]> = JSONParser.parseData(jsonData)

        let exp = expectation(description: "")
        task.upon(.main) { (result) in
            XCTAssert(result.value != nil)
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testParsePrettyPrinting() throws {
        let model = SampleModel(identity: "123456", name: "Hola", amount: 5678)
        let jsonData = try JSONEncoder().encode(model)
        guard let string = JSONParser.parseDataAsJSONPrettyPrint(jsonData) else {
            throw ParseError()
        }

        let sampleString = """
        {\n  \"id\" : \"123456\",\n  \"name\" : \"Hola\",\n  \"amount\" : 5678\n}
        """
        XCTAssert(string == sampleString)
    }
}

struct ParseError: Swift.Error {
}


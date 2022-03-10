//
//  Created by Pierluigi Cifani on 08/06/2017.
//

import XCTest
import BSWFoundation

class JSONParserTests: XCTestCase {

    struct SampleModel: Codable {
        let identity: String
        let name: String
        let amount: Double

        enum CodingKeys : String, CodingKey {
            case identity = "id", name, amount
        }
    }

    struct SampleModelWithDate: Codable, DateDecodingStrategyProvider {
        let date: Date

        enum CodingKeys: String, CodingKey {
            case date = "date"
        }
        
        public static var dateDecodingStrategy: DateFormatter {
            someFormatter
        }
    }
    
    func testParsing_forSwiftConcurency() async throws {
        let model = SampleModel(identity: "123456", name: "Hola", amount: 5678)
        let jsonData = try JSONEncoder().encode(model)
        let parsedModel: SampleModel = try JSONParser.parseData(jsonData)
        XCTAssert(model.identity == parsedModel.identity)
    }

    func testParsingWithDate_forSwiftConcurency() throws {
        let sampleString = """
        {\"date\":\"2021-12-20T09:32:30+0000\"}
        """
        let model: SampleModelWithDate = try JSONParser.parseData(sampleString.data(using: .utf8)!)
        XCTAssert(Calendar.current.component(.year, from: model.date) == 2021)
        XCTAssert(Calendar.current.component(.month, from: model.date) == 12)
        XCTAssert(Calendar.current.component(.day, from: model.date) == 20)
    }
    
    func testArrayParsing() throws {
        let model1 = SampleModel(identity: "123456", name: "Hola", amount: 5678)
        let model2 = SampleModel(identity: "987642", name: "🍻", amount: 0986)
        let array = [model1, model2]
        let jsonData = try JSONEncoder().encode(array)

        let _: [SampleModel] = try JSONParser.parseData(jsonData)
    }

    func testParsePrettyPrinting() throws {
        let model = SampleModel(identity: "123456", name: "Hola", amount: 5678)
        let jsonData = try JSONEncoder().encode(model)
        guard let string = JSONParser.parseDataAsJSONPrettyPrint(jsonData) else {
            throw ParseError()
        }

        let sampleString = """
        {\"id\":\"123456\",\"name\":\"Hola\",\"amount\":5678}
        """
        XCTAssert(string == sampleString)
    }

    func testEmptyResponseParsing() throws {
        let jsonData = """
        """.data(using: .utf8)!
        let _: VoidResponse = try JSONParser.parseData(jsonData)
    }
}

struct ParseError: Swift.Error { }

private let someFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return formatter
}()

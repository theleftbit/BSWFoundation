#if canImport(Testing)
import Testing
import BSWFoundation
import Foundation

actor JSONParserTests {

    struct SampleModel: Codable {
        let identity: String
        let name: String
        let amount: Double

        enum CodingKeys: String, CodingKey {
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
    
    @Test
    func parsing_forSwiftConcurrency() async throws {
        let model = SampleModel(identity: "123456", name: "Hola", amount: 5678)
        let jsonData = try JSONEncoder().encode(model)
        let parsedModel: SampleModel = try JSONParser.parseData(jsonData)
        #expect(model.identity == parsedModel.identity)
    }

    @Test
    func parsingWithDate_forSwiftConcurrency() throws {
        let sampleString = """
        {\"date\":\"2021-12-20T09:32:30+0000\"}
        """
        let model: SampleModelWithDate = try JSONParser.parseData(sampleString.data(using: .utf8)!)
        #expect(Calendar.current.component(.year, from: model.date) == 2021)
        #expect(Calendar.current.component(.month, from: model.date) == 12)
        #expect(Calendar.current.component(.day, from: model.date) == 20)
    }
    
    struct SampleModelWithDefaultDate: Codable {
        let date: Date
    }

    /// Formats the old `yyyy-MM-dd'T'HH:mm:ssZZZZZ` formatter accepted must keep parsing to the same instant.
    @Test(arguments: [
        ("2026-11-04T12:42:16Z", 1793796136.0),
        ("2026-11-04T12:42:16+00:00", 1793796136.0),
        ("2026-11-04T12:42:16+0000", 1793796136.0),
        ("2026-11-04T12:42:16+01:00", 1793792536.0),
        ("2026-11-04T12:42:16+0100", 1793792536.0),
        ("2026-11-04T12:42:16-05:30", 1793815936.0),
    ])
    func defaultDateParsing(input: String, expected: TimeInterval) throws {
        let model: SampleModelWithDefaultDate = try JSONParser.parseData(Data(#"{"date":"\#(input)"}"#.utf8))
        #expect(model.date.timeIntervalSince1970 == expected)
    }

    /// Formats the old formatter rejected must keep failing.
    @Test(arguments: [
        "2026-11-04T12:42:16",
        "2026-11-04 12:42:16Z",
        "2026-11-04",
        "not a date",
    ])
    func defaultDateParsingRejects(input: String) {
        #expect(throws: JSONParser.Error.self) {
            let _: SampleModelWithDefaultDate = try JSONParser.parseData(Data(#"{"date":"\#(input)"}"#.utf8))
        }
    }

    @Test
    func arrayParsing() throws {
        let model1 = SampleModel(identity: "123456", name: "Hola", amount: 5678)
        let model2 = SampleModel(identity: "987642", name: "🍻", amount: 0986)
        let array = [model1, model2]
        let jsonData = try JSONEncoder().encode(array)

        let _: [SampleModel] = try JSONParser.parseData(jsonData)
    }

    @Test
    func parsePrettyPrinting() throws {
        let model = SampleModel(identity: "123456", name: "Hola", amount: 5678)
        let jsonData = try JSONEncoder().encode(model)
        guard let string = JSONParser.parseDataAsJSONPrettyPrint(jsonData) else {
            throw ParseError()
        }

        let sampleString = """
        {\"amount\":5678,\"id\":\"123456\",\"name\":\"Hola\"}
        """
        #expect(string == sampleString)
    }
    
    @Test
    func emptyResponseParsing() throws {
        let jsonData = "".data(using: .utf8)!
        let _: VoidResponse = try JSONParser.parseData(jsonData)
    }

    @Test
    func throwsError() throws {
        let jsonData = "".data(using: .utf8)!
        #expect(throws: JSONParser.Error.self, performing: {
            let _: SampleModel = try JSONParser.parseData(jsonData)
        })
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

#endif

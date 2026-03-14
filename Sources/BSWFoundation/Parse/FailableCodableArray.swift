#if canImport(FoundationInternationalization)
import FoundationInternationalization
#endif
import Foundation

#if SKIP || !os(Android)
import OSLog
#endif

public struct FailableCodableArray<Element : Decodable> : Decodable {

    public let elements: [Element]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let elements = try container.decode([FailableDecodable<Element>].self)
        self.elements = elements.compactMap { $0.base }
    }
}

extension FailableCodableArray: Sendable where Element: Sendable {}

extension FailableCodableArray: DateDecodingStrategyProvider where Element: DateDecodingStrategyProvider {
    public static var dateDecodingStrategy: DateFormatter {
        return Element.dateDecodingStrategy
    }
}

private struct FailableDecodable<Base : Decodable> : Decodable {

    let base: Base?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.base = {
            do {
                return try container.decode(Base.self)
            } catch let error {
                let logger = Logger(subsystem: submoduleName("FailableDecodable"), category: "error")
                logger.warning("Error decoding \(Base.self): \(error)")
                return nil
            }
        }()
    }
}

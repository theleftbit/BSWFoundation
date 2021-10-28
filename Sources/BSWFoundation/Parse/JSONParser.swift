//
//  Created by Pierluigi Cifani.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
//

import Foundation
import Task; import Deferred

public enum JSONParser {
    
    private static let queue = DispatchQueue(label: "com.bswfoundation.JSONParser")
    public static let jsonDecoder = JSONDecoder()
    public static let Options: JSONSerialization.ReadingOptions = [.allowFragments]
    
    public static func parseData<T: Decodable>(_ data: Data) -> Task<T> {
        Task.fromSwiftConcurrency { try await self.parseData(data) }
    }

    public static func parseData<T: Decodable>(_ data: Data) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let result: Swift.Result<T, Error> = self.parseData(data)
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public static func dataIsNull(_ data: Data) -> Bool {
        guard let j = try? JSONSerialization.jsonObject(with: data, options: JSONParser.Options) else {
            return false
        }
        
        guard let _ = j as? NSNull else {
            return false
        }
        
        return true
    }

    public static func parseDataAsJSONPrettyPrint(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: JSONParser.Options) else { return nil }
        let options: JSONSerialization.WritingOptions = {
            if #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                return [.fragmentsAllowed,.withoutEscapingSlashes]
            } else {
                return [.fragmentsAllowed]
            }
        }()
        guard let prettyPrintedData = try? JSONSerialization.data(withJSONObject: json, options: options) else { return nil }
        return String(data: prettyPrintedData, encoding: .utf8)
    }

    public static func errorMessageFromData(_ data: Data) -> String? {
        guard let j = try? JSONSerialization.jsonObject(with: data, options: JSONParser.Options) else {
            return nil
        }
        guard let dictionary = j as? [String: String] else {
            return nil
        }        
        return dictionary["error"]
    }

    static public func parseData<T: Decodable>(_ data: Data) -> Swift.Result<T, Error> {

        guard T.self != VoidResponse.self else {
            let response = VoidResponse.init() as! T
            return .success(response)
        }
        
        if let provider = T.self as? DateDecodingStrategyProvider.Type {
            jsonDecoder.dateDecodingStrategy = .formatted(provider.dateDecodingStrategy)
        } else {
            jsonDecoder.dateDecodingStrategy = .formatted(iso8601DateFormatter)
        }

        let result: Swift.Result<T, Error>
        do {
            let output: T = try jsonDecoder.decode(T.self, from: data)
            result = .success(output)
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .keyNotFound(let missingKey, let context):
                print("*ERROR* decoding, key \"\(missingKey)\" is missing, Context: \(context)")
                result = .failure(Error.malformedSchema)
            case .typeMismatch(let type, let context):
                print("*ERROR* decoding, type \"\(type)\" mismatched, context: \(context)")
                result = .failure(Error.malformedSchema)
            case .valueNotFound(let type, let context):
                print("*ERROR* decoding, value not found \"\(type)\", context: \(context)")
                result = .failure(Error.malformedSchema)
            case .dataCorrupted(let context):
                print("*ERROR* Data Corrupted \"\(context)\")")
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    print("*ERROR* incoming JSON: \(string)")
                }
                result = .failure(Error.malformedJSON)
            @unknown default:
                result = .failure(Error.unknownError)
            }
        } catch {
            result = .failure(Error.unknownError)
        }
        
        return result
    }

    //MARK: Error

    public enum Error: Swift.Error {
        case malformedJSON
        case malformedSchema
        case unknownError
        case canceled
    }
}

public protocol DateDecodingStrategyProvider {
    static var dateDecodingStrategy: DateFormatter { get }
}

private var iso8601DateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return formatter
}

extension Array: DateDecodingStrategyProvider where Element: DateDecodingStrategyProvider {
    public static var dateDecodingStrategy: DateFormatter {
        return Element.dateDecodingStrategy
    }
}

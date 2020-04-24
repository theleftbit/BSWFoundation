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
        let task: Task<T> = Task.async(upon: queue, onCancel: Error.canceled) {
            let result: Task<T>.Result = self.parseData(data)
            return try result.extract()
        }
        return task
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

    static public func parseData<T: Decodable>(_ data: Data) -> Task<T>.Result {

        guard T.self != VoidResponse.self else {
            let response = VoidResponse.init() as! T
            return .success(response)
        }
        
        /// Turns out that on iOS 12,  parsing basic types using
        /// Swift's `Decodable` is failing for some unknown
        /// reasons. To lazy to file a radar...
        /// So here we're instead using the good and trusted
        /// `NSJSONSerialization` class
        if T.self == Bool.self || T.self == Int.self || T.self == String.self {
            if let output = try? JSONSerialization.jsonObject(with: data, options: JSONParser.Options) as? T {
                return .success(output)
            } else {
                return .failure(Error.malformedJSON)
            }
        }
        
        if let provider = T.self as? DateDecodingStrategyProvider.Type {
            jsonDecoder.dateDecodingStrategy = .formatted(provider.dateDecodingStrategy)
        } else {
            jsonDecoder.dateDecodingStrategy = .formatted(iso8601DateFormatter)
        }

        let result: Task<T>.Result
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

#if canImport(Combine)

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension JSONParser {
    
    static func parseData<T: Decodable>(_ data: Data) -> CombineTask<T> {
        let task: Task<T> = self.parseData(data)
        return task.future
    }

    static func parseData<T: Decodable>(_ data: Data) -> Swift.Result<T, Swift.Error> {
        return parseData(data).swiftResult
    }
}

#endif

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

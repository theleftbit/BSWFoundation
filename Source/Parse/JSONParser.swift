//
//  Created by Pierluigi Cifani.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
//

import Foundation
import Deferred

public enum JSONParser {
    
    fileprivate static let queue = queueForSubmodule("JSONParser")
    fileprivate static let jsonDecoder = JSONDecoder()

    public static func parseData<T: Decodable>(_ data: Data) -> Task<T> {
        let deferred = Deferred<Task<T>.Result>()
        queue.addOperation {
            deferred.fill(with: parseData(data))
        }
        return Task(future: Future(deferred))
    }

    public static func dataIsNull(_ data: Data) -> Bool {
        guard let j = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return false
        }
        
        guard let _ = j as? NSNull else {
            return false
        }
        
        return true
    }

    public static func parseDataAsJSONPrettyPrint(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else { return nil }
        guard let prettyPrintedData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else { return nil }
        return String(data: prettyPrintedData, encoding: .utf8)
    }

    public static func errorMessageFromData(_ data: Data) -> String? {
        guard let j = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return nil
        }
        guard let dictionary = j as? [String : String] else {
            return nil
        }        
        return dictionary["error"]
    }

    static func parseData<T : Decodable>(_ data: Data) -> Task<T>.Result {
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
                print("*ERROR* Data Corrupted \"\(context)\"")
                result = .failure(Error.malformedJSON)
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
    }
}

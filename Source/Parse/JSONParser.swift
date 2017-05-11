//
//  Created by Pierluigi Cifani.
//  Copyright (c) 2016 Blurred Software SL. All rights reserved.
//

import Decodable
import Deferred

public enum JSONParser {
    
    fileprivate static let queue = queueForSubmodule("JSONParser")

    public static func parseDataAsync<T: Decodable>(_ data: Data) -> Task<T> {
        
        let deferred = Deferred<Task<T>.Result>()
        
        queue.addOperation {
            deferred.fill(with: parseData(data))
        }
        
        return Task(future: Future(deferred))
    }

    public static func parseDataAsync<T : Decodable>(_ data: Data) -> Task<[T]> {
        
        let deferred = Deferred<Task<[T]>.Result>()
        
        queue.addOperation {
            deferred.fill(with: parseData(data))
        }
        
        return Task(future: Future(deferred))
    }

    
    public static func parseData<T : Decodable>(_ data:Data) -> Task<T>.Result {
        
        guard let j = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return .failure(DataParseErrorKind.malformedJSON)
        }
        
        return parseJSON(j as AnyObject)
    }
    
    public static func parseData<T : Decodable>(_ data: Data) -> Task<[T]>.Result {
        
        guard let j = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return .failure(DataParseErrorKind.malformedJSON)
        }
        
        return parseJSON(j as AnyObject)
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
    
    public static func errorMessageFromData(_ data: Data) -> String? {
        guard let j = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return nil
        }
        
        guard let dictionary = j as? [String : String] else {
            return nil
        }
        
        return dictionary["error"]
    }

    //MARK: - Private
    
    fileprivate static func parseJSON<T : Decodable>(_ j: AnyObject) -> Task<T>.Result {
        let result : Task<T>.Result
        do {
            let output : T = try T.decode(j)
            result = .success(output)
        } catch let error {
            
            if let typeMismatchError = error as? DecodingError {
                
                switch typeMismatchError {
                case .typeMismatch(let expected, let actual, let metadata):
                    print("*ERROR* decoding, type \"\(actual)\" mismatched, expected \"\(expected)\" type, path: \(metadata.path)")
                    result = .failure(DataParseErrorKind.malformedSchema)
                case .missingKey(let key, _):
                    print("*ERROR* decoding, key \"\(key)\" is missing")
                    result = .failure(DataParseErrorKind.malformedSchema)
                default:
                    print("unknownError decoding json")
                    result = .failure(DataParseErrorKind.unknownError)
                }
            } else {
                result = .failure(DataParseErrorKind.unknownError)
            }
            
            print("Received JSON: \(j)")
        }
        
        return result
    }
    
    fileprivate static func parseJSON<T : Decodable>(_ j: AnyObject) -> Task<[T]>.Result {
        let result : Task<[T]>.Result
        do {
            
            #if DEBUG
                let ignoreInvalidObjects = false
            #else
                let ignoreInvalidObjects = true
            #endif
            
            let output: [T] = try [T].decode(j, ignoreInvalidObjects: ignoreInvalidObjects)
            result = .success(output)
        } catch let error {
            
            if let typeMismatchError = error as? DecodingError {
                
                switch typeMismatchError {
                case .typeMismatch(let expected, let actual, let metadata):
                    print("*ERROR* decoding, type \"\(actual)\" mismatched, expected \"\(expected)\" type, path: \(metadata.path)")
                    result = .failure(DataParseErrorKind.malformedSchema)
                case .missingKey(let key, _):
                    print("*ERROR* decoding, key \"\(key)\" is missing")
                    result = .failure(DataParseErrorKind.malformedSchema)
                default:
                    print("unknownError decoding json")
                    result = .failure(DataParseErrorKind.unknownError)
                }
            } else {
                result = .failure(DataParseErrorKind.unknownError)
            }
            
            print("Received JSON: \(j)")
        }
        
        return result
    }
}

//MARK: ErrorType

public enum DataParseErrorKind: Error {
    case malformedJSON
    case malformedSchema
    case unknownError
}

//MARK: Foundation Types

extension URL: Decodable {
    
    public static func decode(_ j: Any) throws -> URL {
        
        guard let urlString = j as? String else {
            throw DecodingError.typeMismatch(expected: String.self, actual: type(of: j), DecodingError.Metadata(object: j))
        }
        
        guard let _ = URL(string: urlString) else {
            throw DecodingError.rawRepresentableInitializationError(rawValue: urlString, DecodingError.Metadata(object: j))
        }
        
        return self.init(string: urlString)!
    }
}

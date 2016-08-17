//
//  Created by Pierluigi Cifani.
//  Copyright (c) 2016 Blurred Software SL. All rights reserved.
//

import Decodable
import Deferred

public enum JSONParser {
    
    fileprivate static let queue = queueForSubmodule("JSONParser")

    public static func parseDataAsync<T: Decodable>(_ data: Data) -> Future<Result<T>> {
        
        let deferred = Deferred<Result<T>>()
        
        queue.addOperation {
            deferred.fill(parseData(data))
        }
        
        return Future(deferred)
    }

    public static func parseDataAsync<T : Decodable>(_ data: Data) -> Future<Result<[T]>> {
        
        let deferred = Deferred<Result<[T]>>()
        
        queue.addOperation {
            deferred.fill(parseData(data))
        }
        
        return Future(deferred)
    }

    
    public static func parseData<T : Decodable>(_ data:Data) -> Result<T> {
        
        guard let j = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return Result(error: DataParseErrorKind.malformedJSON)
        }
        
        return parseJSON(j as AnyObject)
    }
    
    public static func parseData<T : Decodable>(_ data: Data) -> Result<[T]> {
        
        guard let j = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return Result(error: DataParseErrorKind.malformedJSON)
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
    
    fileprivate static func parseJSON<T : Decodable>(_ j: AnyObject) -> Result<T> {
        let result : Result<T>
        do {
            let output : T = try T.decode(j)
            result = Result(output)
        } catch let error {
            
            if let typeMismatchError = error as? TypeMismatchError {
                print("*ERROR* decoding, type \"\(typeMismatchError.receivedType)\" mismatched, expected \"\(typeMismatchError.expectedType)\" type, path: \(typeMismatchError.path)")
                result = Result(error: DataParseErrorKind.malformedSchema)
            } else if let missingKeyError = error as? MissingKeyError {
                print("*ERROR* decoding, key \"\(missingKeyError.key)\" is missing")
                result = Result(error: DataParseErrorKind.malformedSchema)
            } else if let rawRepresentationError = error as? RawRepresentableInitializationError {
                print("*ERROR* decoding, \(rawRepresentationError.debugDescription)")
                result = Result(error: DataParseErrorKind.malformedSchema)
            } else {
                result = Result(error: DataParseErrorKind.unknownError)
            }
            
            print("Received JSON: \(j)")
        }
        
        return result
    }
    
    fileprivate static func parseJSON<T : Decodable>(_ j: AnyObject) -> Result<[T]> {
        let result : Result<[T]>
        do {
            
            #if DEBUG
                let ignoreInvalidObjects = false
            #else
                let ignoreInvalidObjects = true
            #endif
            
            let output: [T] = try [T].decode(j, ignoreInvalidObjects: ignoreInvalidObjects)
            result = Result(output)
        } catch let error {
            
            if let typeMismatchError = error as? TypeMismatchError {
                print("*ERROR* decoding, type \"\(typeMismatchError.receivedType)\" mismatched, expected \"\(typeMismatchError.expectedType)\" type, path: \(typeMismatchError.path)")
                result = Result(error: DataParseErrorKind.malformedSchema)
            } else if let missingKeyError = error as? MissingKeyError {
                print("*ERROR* decoding, key \"\(missingKeyError.key)\" is missing")
                result = Result(error: DataParseErrorKind.malformedSchema)
            } else if let rawRepresentationError = error as? RawRepresentableInitializationError {
                print("*ERROR* decoding, \(rawRepresentationError.debugDescription)")
                result = Result(error: DataParseErrorKind.malformedSchema)
            } else {
                result = Result(error: DataParseErrorKind.unknownError)
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

extension Date : Decodable {
    
    fileprivate struct DateFormatter {
        static let ISO8601Formatter: Foundation.DateFormatter = {
            let dateFormatter = Foundation.DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return dateFormatter
        }()
        
        static let SimpleFormatter: Foundation.DateFormatter = {
            let dateFormatter = Foundation.DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = NSLocale.current
            return dateFormatter
        }()
    }
    
    public static func decode(_ j: AnyObject) throws -> Date {
        
        guard let dateString = j as? String else {
            throw TypeMismatchError(expectedType: String.self, receivedType: type(of: j), object: j)
        }

        if let date = DateFormatter.ISO8601Formatter.date(from: dateString) {
            return self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
        }
        else if let date = DateFormatter.SimpleFormatter.date(from: dateString) {
            return self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
        }
        else {
            throw RawRepresentableInitializationError(type: Date.self, rawValue: dateString, object: j)
        }
    }
}

extension URL : Decodable {
    
    public static func decode(_ j: AnyObject) throws -> URL {
        
        guard let urlString = j as? String else {
            throw TypeMismatchError(expectedType: String.self, receivedType: type(of: j), object: j)
        }
        
        guard let _ = URL(string: urlString) else {
            throw RawRepresentableInitializationError(type: URL.self, rawValue: urlString, object: j)
        }
        
        return self.init(string: urlString)!
    }
}

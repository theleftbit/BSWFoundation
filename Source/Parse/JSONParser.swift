//
//  Created by Pierluigi Cifani.
//  Copyright (c) 2016 Blurred Software SL. All rights reserved.
//

import Decodable
import Deferred

public enum JSONParser {
    
    private static let queue = queueForSubmodule("JSONParser")

    public static func parseDataAsync<T: Decodable>(data: NSData) -> Future<Result<T>> {
        
        let deferred = Deferred<Result<T>>()
        
        queue.addOperationWithBlock {
            deferred.fill(parseData(data))
        }
        
        return Future(deferred)
    }

    public static func parseDataAsync<T : Decodable>(data: NSData) -> Future<Result<[T]>> {
        
        let deferred = Deferred<Result<[T]>>()
        
        queue.addOperationWithBlock {
            deferred.fill(parseData(data))
        }
        
        return Future(deferred)
    }

    
    public static func parseData<T : Decodable>(data:NSData) -> Result<T> {
        
        guard let j = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
            return Result(error: DataParseErrorKind.MalformedJSON)
        }
        
        return parseJSON(j)
    }
    
    public static func parseData<T : Decodable>(data: NSData) -> Result<[T]> {
        
        guard let j = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
            return Result(error: DataParseErrorKind.MalformedJSON)
        }
        
        return parseJSON(j)
    }

    public static func dataIsNull(data: NSData) -> Bool {
        guard let j = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
            return false
        }
        
        guard let _ = j as? NSNull else {
            return false
        }
        
        return true
    }
    
    public static func errorMessageFromData(data: NSData) -> String? {
        guard let j = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
            return nil
        }
        
        guard let dictionary = j as? [String : String] else {
            return nil
        }
        
        return dictionary["error"]
    }

    //MARK: - Private
    
    private static func parseJSON<T : Decodable>(j: AnyObject) -> Result<T> {
        let result : Result<T>
        do {
            let output : T = try T.decode(j)
            result = Result(output)
        } catch let error {
            
            if let typeMismatchError = error as? TypeMismatchError {
                print("*ERROR* decoding, type \"\(typeMismatchError.receivedType)\" mismatched, expected \"\(typeMismatchError.expectedType)\" type, path: \(typeMismatchError.path)")
                result = Result(error: DataParseErrorKind.MalformedSchema)
            } else if let missingKeyError = error as? MissingKeyError {
                print("*ERROR* decoding, key \"\(missingKeyError.key)\" is missing")
                result = Result(error: DataParseErrorKind.MalformedSchema)
            } else if let rawRepresentationError = error as? RawRepresentableInitializationError {
                print("*ERROR* decoding, \(rawRepresentationError.debugDescription)")
                result = Result(error: DataParseErrorKind.MalformedSchema)
            } else {
                result = Result(error: DataParseErrorKind.UnknownError)
            }
            
            print("Received JSON: \(j)")
        }
        
        return result
    }
    
    private static func parseJSON<T : Decodable>(j: AnyObject) -> Result<[T]> {
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
                result = Result(error: DataParseErrorKind.MalformedSchema)
            } else if let missingKeyError = error as? MissingKeyError {
                print("*ERROR* decoding, key \"\(missingKeyError.key)\" is missing")
                result = Result(error: DataParseErrorKind.MalformedSchema)
            } else if let rawRepresentationError = error as? RawRepresentableInitializationError {
                print("*ERROR* decoding, \(rawRepresentationError.debugDescription)")
                result = Result(error: DataParseErrorKind.MalformedSchema)
            } else {
                result = Result(error: DataParseErrorKind.UnknownError)
            }
            
            print("Received JSON: \(j)")
        }
        
        return result
    }
}

//MARK: ErrorType

public enum DataParseErrorKind: ResultErrorType {
    case MalformedJSON
    case MalformedSchema
    case UnknownError
}

//MARK: Foundation Types

extension NSDate : Decodable {
    
    private struct ISO8601DateFormatter {
        static let Formatter: NSDateFormatter = {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return dateFormatter
        }()
    }
    
    public class func decode(j: AnyObject) throws -> Self {
        
        guard let dateString = j as? String else {
            throw TypeMismatchError(expectedType: String.self, receivedType: j.dynamicType, object: j)
        }

        guard let date = ISO8601DateFormatter.Formatter.dateFromString(dateString) else {
            throw RawRepresentableInitializationError(type: NSDate.self, rawValue: dateString, object: j)
        }

        return self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
    }
}

extension NSURL : Decodable {
    
    public class func decode(j: AnyObject) throws -> Self {
        
        guard let urlString = j as? String else {
            throw TypeMismatchError(expectedType: String.self, receivedType: j.dynamicType, object: j)
        }
        
        guard let _ = NSURL(string: urlString) else {
            throw RawRepresentableInitializationError(type: NSURL.self, rawValue: urlString, object: j)
        }
        
        return self.init(string: urlString)!
    }
}

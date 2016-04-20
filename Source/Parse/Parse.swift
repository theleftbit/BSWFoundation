//
//  Created by Pierluigi Cifani on 04/06/15.
//  Copyright (c) 2015 Wallapop SL. All rights reserved.
//

import Decodable
import Result
import Deferred

private let ParseSubmoduleName = "parse"
private let ParseQueue = queueForSubmodule(parseSubmoduleName)

public func parseData<T : Decodable>(data:NSData) -> Result<T, FoundationErrorKind> {

    guard let j = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
        return Result(error: FoundationErrorKind(wrappedError: DataParseErrorKind.MalformedJSON))
    }
    
    return parseJSON(j)
}

public func parseData<T : Decodable>(data:NSData) -> Result<[T], FoundationErrorKind> {
    
    guard let j = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
        return Result(error: FoundationErrorKind(wrappedError: DataParseErrorKind.MalformedJSON))
    }
    
    return parseJSON(j)
}

public func parseJSON<T : Decodable>(j:AnyObject) -> Result<T, FoundationErrorKind> {
    let result : Result<T, FoundationErrorKind>
    do {
        let output : T = try T.decode(j)
        result = Result(output)
    } catch let error {
        
        if let typeMismatchError = error as? TypeMismatchError {
            print("*ERROR* decoding, type \(typeMismatchError.receivedType) mismatched, expected \(typeMismatchError.expectedType) type")
            result = Result(error: FoundationErrorKind(wrappedError: DataParseErrorKind.MalformedSchema))
        } else if let missingKeyError = error as? MissingKeyError {
            print("*ERROR* decoding, key \(missingKeyError.key) is missing")
            result = Result(error: FoundationErrorKind(wrappedError: DataParseErrorKind.MalformedSchema))
        } else {
            result = Result(error: FoundationErrorKind(wrappedError: DataParseErrorKind.UnknownError))
        }
    }
    
    return result
}

public func parseJSON<T : Decodable>(j:AnyObject) -> Result<[T], FoundationErrorKind> {
    let result : Result<[T], FoundationErrorKind>
    do {
        let output : [T] = try [T].decode(j)
        result = Result(output)
    } catch let error {
    
        if let typeMismatchError = error as? TypeMismatchError {
            print("*ERROR* decoding, type \(typeMismatchError.receivedType) mismatched, expected \(typeMismatchError.expectedType) type")
            result = Result(error: FoundationErrorKind(wrappedError: DataParseErrorKind.MalformedSchema))
        } else if let missingKeyError = error as? MissingKeyError {
            print("*ERROR* decoding, key \(missingKeyError.key) is missing")
            result = Result(error: FoundationErrorKind(wrappedError: DataParseErrorKind.MalformedSchema))
        } else {
            result = Result(error: FoundationErrorKind(wrappedError: DataParseErrorKind.UnknownError))
        }
    }
    
    return result
}

//MARK: ErrorType

public enum DataParseErrorKind : Int, ResultErrorType {
    case MalformedJSON      = -10
    case MalformedSchema    = -20
    case UnknownError       = -40
}

//MARK: Foundation Types

extension NSDate : Decodable {
    public class func decode(j: AnyObject) throws -> Self {
        
        guard let epochTime = j as? Double else {
            throw TypeMismatchError(expectedType: String.self, receivedType: j.dynamicType, object: j)
        }
        
        return self.init(timeIntervalSince1970: epochTime)
    }
}

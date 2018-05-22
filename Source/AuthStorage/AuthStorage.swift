//
//  Created by Pierluigi Cifani on 09/02/2017.
//  Copyright (c) 2017 TheLeftBit SL. All rights reserved.
//

import Foundation
import KeychainAccess

public class AuthStorage {

    public static let defaultStorage = AuthStorage()
    fileprivate let keychain = Keychain(service: Bundle.main.bundleIdentifier!)
    fileprivate var jwt: JWT? {
        get {
            guard let jwtString = keychain[Keys.JWT] else { return nil}
            return try? decode(jwt: jwtString)
        }
    }

    fileprivate let userDefaults = UserDefaults.standard

    init() {
        guard !userDefaults.bool(forKey: Keys.HasAppBeenExecuted) else {
            return
        }

        // Clear the keychain on app's first launch, so the user
        // has to log-in again after an app delete
        clearKeychain()
        userDefaults.set(true, forKey: Keys.HasAppBeenExecuted)
        userDefaults.synchronize()
    }

    public func jwtToken() -> String? {
        let token = keychain[Keys.JWT]
        return token
    }

    public func setJTWToken(_ authToken: String) throws {
        _ = try decode(jwt: authToken)
        keychain[Keys.JWT] = authToken
    }

    public var tokenIsExpired: Bool {
        guard let jwt = self.jwt else { return false }
        return jwt.expired
    }

    public func userID() -> String? {
        return keychain[Keys.UserID]
    }

    public func setUserID(_ userID: String) {
        keychain[Keys.UserID] = userID
    }

    public func authToken() -> String? {
        return keychain[Keys.AuthToken]
    }

    public func setAuthToken(_ token: String) {
        keychain[Keys.AuthToken] = token
    }

    public func clearKeychain() {
        keychain[Keys.JWT] = nil
        keychain[Keys.AuthToken] = nil
        keychain[Keys.UserID] = nil
    }
}

private struct Keys {
    static let JWT = "JWT"
    static let AuthToken = "AuthToken"
    static let UserID = "UserID"
    static let HasAppBeenExecuted = "HasAppBeenExecuted"
}


// A0JWT.swift
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// JWTDecode.swift
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/**
 Decodes a JWT token into an object that holds the decoded body (along with token header and signature parts).
 If the token cannot be decoded a `NSError` will be thrown.

 - parameter jwt: jwt string value to decode

 - throws: an error if the JWT cannot be decoded

 - returns: a decoded token as an instance of JWT
 */
public func decode(jwt: String) throws -> JWT {
    return try DecodedJWT(jwt: jwt)
}

struct DecodedJWT: JWT {

    let header: [String: Any]
    let body: [String: Any]
    let signature: String?
    let string: String

    init(jwt: String) throws {
        let parts = jwt.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw DecodeError.invalidPartCount(jwt, parts.count)
        }

        self.header = try decodeJWTPart(parts[0])
        self.body = try decodeJWTPart(parts[1])
        self.signature = parts[2]
        self.string = jwt
    }

    var expiresAt: Date? { return claim(name: "exp").date }
    var issuer: String? { return claim(name: "iss").string }
    var subject: String? { return claim(name: "sub").string }
    var audience: [String]? { return claim(name: "aud").array }
    var issuedAt: Date? { return claim(name: "iat").date }
    var notBefore: Date? { return claim(name: "nbf").date }
    var identifier: String? { return claim(name: "jti").string }

    var expired: Bool {
        guard let date = self.expiresAt else {
            return false
        }
        return date.compare(Date()) != ComparisonResult.orderedDescending
    }
}

/**
 *  JWT Claim
 */
public struct Claim {

    /// raw value of the claim
    let value: Any?

    /// value of the claim as `String`
    public var string: String? {
        return self.value as? String
    }

    /// value of the claim as `Double`
    public var double: Double? {
        let double: Double?
        if let string = self.string {
            double = Double(string)
        } else {
            double = self.value as? Double
        }
        return double
    }

    /// value of the claim as `Int`
    public var integer: Int? {
        let integer: Int?
        if let string = self.string {
            integer = Int(string)
        } else if let double = self.value as? Double {
            integer = Int(double)
        } else {
            integer = self.value as? Int
        }
        return integer
    }

    /// value of the claim as `NSDate`
    public var date: Date? {
        guard let timestamp: TimeInterval = self.double else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    /// value of the claim as `[String]`
    public var array: [String]? {
        if let array = value as? [String] {
            return array
        }
        if let value = self.string {
            return [value]
        }
        return nil
    }
}

private func base64UrlDecode(_ value: String) -> Data? {
    var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
    }
    return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
}

private func decodeJWTPart(_ value: String) throws -> [String: Any] {
    guard let bodyData = base64UrlDecode(value) else {
        throw DecodeError.invalidBase64Url(value)
    }

    guard let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
        throw DecodeError.invalidJSON(value)
    }

    return payload
}

// JWT.swift
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/**
 *  Protocol that defines what a decoded JWT token should be.
 */
public protocol JWT {
    /// token header part contents
    var header: [String: Any] { get }
    /// token body part values or token claims
    var body: [String: Any] { get }
    /// token signature part
    var signature: String? { get }
    /// jwt string value
    var string: String { get }

    /// value of `exp` claim if available
    var expiresAt: Date? { get }
    /// value of `iss` claim if available
    var issuer: String? { get }
    /// value of `sub` claim if available
    var subject: String? { get }
    /// value of `aud` claim if available
    var audience: [String]? { get }
    /// value of `iat` claim if available
    var issuedAt: Date? { get }
    /// value of `nbf` claim if available
    var notBefore: Date? { get }
    /// value of `jti` claim if available
    var identifier: String? { get }

    /// Checks if the token is currently expired using the `exp` claim. If there is no claim present it will deem the token not expired
    var expired: Bool { get }
}

public extension JWT {

    /**
     Return a claim by it's name

     - parameter name: name of the claim in the JWT

     - returns: a claim of the JWT
     */
    public func claim(name: String) -> Claim {
        let value = self.body[name]
        return Claim(value: value)
    }
}

// Errors.swift
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/**
 JWT decode error codes

 - InvalidBase64UrlValue: when either the header or body parts cannot be base64 decoded
 - InvalidJSONValue:      when either the header or body decoded values is not a valid JSON object
 - InvalidPartCount:      when the token doesnt have the required amount of parts (header, body and signature)
 */
public enum DecodeError: LocalizedError {
    case invalidBase64Url(String)
    case invalidJSON(String)
    case invalidPartCount(String, Int)

    public var localizedDescription: String {
        switch self {
        case .invalidJSON(let value):
            return NSLocalizedString("Malformed jwt token, failed to parse JSON value from base64Url \(value)", comment: "Invalid JSON value inside base64Url")
        case .invalidPartCount(let jwt, let parts):
            return NSLocalizedString("Malformed jwt token \(jwt) has \(parts) parts when it should have 3 parts", comment: "Invalid amount of jwt parts")
        case .invalidBase64Url(let value):
            return NSLocalizedString("Malformed jwt token, failed to decode base64Url value \(value)", comment: "Invalid JWT token base64Url value")
        }
    }
}

// A0JWT.swift
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/// Decodes a JWT
@objc(A0JWT)
public class _JWT: NSObject {

    var jwt: JWT

    init(jwt: JWT) {
        self.jwt = jwt
    }

    /// token header part
    @objc public var header: [String: Any] {
        return self.jwt.header
    }

    /// token body part or claims
    @objc public var body: [String: Any] {
        return self.jwt.body
    }

    /// token signature part
    @objc public var signature: String? {
        return self.jwt.signature
    }

    /// value of the `exp` claim
    @objc public var expiresAt: Date? {
        return self.jwt.expiresAt as Date?
    }

    /// value of the `expired` field
    @objc public var expired: Bool {
        return self.jwt.expired
    }

    /**
     Creates a new instance of `A0JWT` and decodes the given jwt token.

     :param: jwtValue of the token to decode

     :returns: a new instance of `A0JWT` that holds the decode token
     */
    @objc public class func decode(jwt jwtValue: String) throws -> _JWT {
        let jwt = try DecodedJWT(jwt: jwtValue)
        return _JWT(jwt: jwt)
    }
}

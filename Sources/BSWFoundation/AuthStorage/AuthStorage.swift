//
//  Created by Pierluigi Cifani on 09/02/2017.
//  Copyright (c) 2017 TheLeftBit SL. All rights reserved.
//
#if os(Android)
#else

import Foundation
import KeychainAccess

/// A class that's useful to store sensitive information using the device's Keychain.
public class AuthStorage {
    
    /// A standard `AuthStorage` with a `.simple` style.
    public static let defaultStorage = AuthStorage()

    @UserDefaultsBacked(key: Keys.HasAppBeenExecuted, defaultValue: false)
    private var appBeenExecuted: Bool!
    private let keychain: Keychain

    /// Where should `AppStorage` put it's values.
    public enum Style: Equatable {
        /// Uses the Bundle ID of the app to namespace the values
        case simple
        /// Pass the ID of the App Group and the AppName _without_ `Bundle` APIs
        case appGroup(id: String, appName: String)
    }
    
    public init(style: Style = .simple) {
        self.keychain = {
            switch style {
            case .simple:
                return Keychain(service: Bundle.main.bundleIdentifier!)
            case .appGroup(let id, let appName):
                return Keychain(service: appName, accessGroup: id)
            }
        }()
        
        if appBeenExecuted == false, style == .simple {
            // Clear the keychain on app's first launch, so the user
            // has to log-in again after an app delete
            clearKeychain()
            appBeenExecuted = true
        }
    }

    public var jwtToken: String? {
        get {
            keychain[Keys.JWT]
        } set {
            keychain[Keys.JWT] = newValue
        }
    }
    
    public var userID: String? {
        get {
            keychain[Keys.UserID]
        } set {
            keychain[Keys.UserID] = newValue
        }
    }
    
    public var authToken: String? {
        get {
            keychain[Keys.AuthToken]
        } set {
            keychain[Keys.AuthToken] = newValue
        }
    }
    
    public var refreshToken: String? {
        get {
            keychain[Keys.RefreshToken]
        } set {
            keychain[Keys.RefreshToken] = newValue
        }
    }
    
    public var tokenIsExpired: Bool {
        guard let jwt = self.jwt else { return false }
        return jwt.expired
    }
    
    public func clearKeychain() {
        self.jwtToken = nil
        self.authToken = nil
        self.userID = nil
        self.refreshToken = nil
    }
    
    private var jwt: JWT? {
        get {
            guard let jwtString = jwtToken else { return nil}
            return try? decode(jwt: jwtString)
        }
    }
}

public extension AuthStorage {
    static func extractBodyFromJWT(_ jwtString: String) -> [String: Any]? {
        guard let jwt = try? DecodedJWT(jwt: jwtString) else { return nil }
        return jwt.body
    }
}

private struct Keys {
    static let JWT = "JWT"
    static let AuthToken = "AuthToken"
    static let UserID = "UserID"
    static let RefreshToken = "RefreshToken"
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
    func claim(name: String) -> Claim {
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

#endif

//
//  Browser networking for BSWFoundation on WebAssembly.
//

#if os(WASI)

import Foundation
import HTTPTypes
import JavaScriptKit
import JavaScriptFoundationCompat


// MARK: Platforms without URLSession (e.g. WASM)

extension APIClient {
    
    static func makeDefaultNetworkFetcher(environment: Environment) -> APIClientNetworkFetcher {
        return FetchNetworkFetcher()
    }
}

/// An ``APIClientNetworkFetcher`` backed by the browser's `fetch` API via JavaScriptKit.
///
/// This is the default fetcher on WebAssembly, where `URLSession` is unavailable.
///
/// - Important: The host application must call
///   ``BSWBrowserRuntime/installJavaScriptEventLoop()`` once at startup, before creating this
///   fetcher or spawning async work.
private struct FetchNetworkFetcher: APIClientNetworkFetcher {
    
    init() {
        guard BSWBrowserRuntime.isJavaScriptEventLoopInstalled else {
            fatalError("BSWFoundation: call BSWBrowserRuntime.installJavaScriptEventLoop() once at startup before creating APIClient or FetchNetworkFetcher.")
        }
    }
    
    public func perform(_ request: APIClient.OutboundRequest) async throws -> APIClient.Response {
        // Uploading a file by path is meaningless in the browser sandbox.
        guard request.fileToUpload == nil else {
            throw APIClient.Error.encodingRequestFailed
        }
        guard let url = request.httpRequest.url else {
            throw APIClient.Error.malformedURL
        }
        guard let fetch = JSObject.global.fetch.object else {
            throw APIClient.Error.malformedResponse
        }
        
        // Build the `fetch` options object: { method, headers, body }.
        let options = JSObject()
        options["method"] = .string(request.httpRequest.method.rawValue)
        
        let headers = JSObject()
        for field in request.httpRequest.headerFields {
            headers[field.name.rawName] = .string(field.value)
        }
        options["headers"] = headers.jsValue
        
        if let body = request.body {
            options["body"] = body.jsValue // Data -> Uint8Array (JavaScriptFoundationCompat)
        }
        
        // fetch(url, options) -> Promise<Response>
        let responseValue = try await awaitPromise(fetch(url.absoluteString, options))
        guard let response = responseValue.object else {
            throw APIClient.Error.malformedResponse
        }
        
        let statusCode = Int(response.status.number ?? 0)
        
        // response.arrayBuffer() -> Promise<ArrayBuffer>; wrap in Uint8Array and copy to Data.
        let arrayBuffer = try await awaitPromise(response.arrayBuffer!())
        let bytes = JSObject.global.Uint8Array.function!.new(arrayBuffer)
        let data = Data.construct(from: bytes.jsValue) ?? Data()
        
        let httpResponse = HTTPResponse(
            status: .init(code: statusCode),
            headerFields: Self.headerFields(from: response)
        )
        return APIClient.Response(data: data, httpResponse: httpResponse)
    }
    
    /// Awaits a `JSValue` that is expected to wrap a JavaScript `Promise`.
    private func awaitPromise(_ value: JSValue) async throws -> JSValue {
        guard let object = value.object else {
            throw APIClient.Error.malformedResponse
        }
        return try await JSPromise(unsafelyWrapping: object).value
    }
    
    /// Reads a JS `Response.headers` (`Headers` object) into `HTTPFields`.
    /// `Array.from(headers)` yields `[[name, value], …]`, which we walk by index.
    private static func headerFields(from response: JSObject) -> HTTPFields {
        var fields = HTTPFields()
        guard let arrayConstructor = JSObject.global.Array.object,
              let entries = arrayConstructor.from!(response.headers).object else {
            return fields
        }
        let count = Int(entries.length.number ?? 0)
        for index in 0..<count {
            guard let pair = entries[index].object,
                  let name = pair[0].string,
                  let value = pair[1].string,
                  let fieldName = HTTPField.Name(name) else { continue }
            fields[fieldName] = value
        }
        return fields
    }
}
#endif

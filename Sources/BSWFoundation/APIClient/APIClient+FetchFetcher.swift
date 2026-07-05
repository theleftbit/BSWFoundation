//
//  Browser networking for BSWFoundation on WebAssembly.
//

#if os(WASI)
import Foundation
import HTTPTypes
import JavaScriptKit
import JavaScriptEventLoop
import JavaScriptFoundationCompat

/// An ``APIClientNetworkFetcher`` backed by the browser's `fetch` API via JavaScriptKit.
///
/// This is the default fetcher on WebAssembly, where `URLSession` is unavailable.
///
/// - Important: The host application must install the JavaScriptKit event-loop executor once at
///   startup — `JavaScriptEventLoop.installGlobalExecutor()` — otherwise `async`/`await` (and
///   therefore this fetcher) will not run.
public struct FetchNetworkFetcher: APIClientNetworkFetcher {

    public init() {}

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

        // NOTE: response header fields are not yet surfaced (see follow-up); the status code is
        // what `APIClient` validates and is sufficient for the request pipeline.
        let httpResponse = HTTPResponse(status: .init(code: statusCode))
        return APIClient.Response(data: data, httpResponse: httpResponse)
    }

    /// Awaits a `JSValue` that is expected to wrap a JavaScript `Promise`.
    private func awaitPromise(_ value: JSValue) async throws -> JSValue {
        guard let object = value.object else {
            throw APIClient.Error.malformedResponse
        }
        return try await JSPromise(unsafelyWrapping: object).value
    }
}
#endif

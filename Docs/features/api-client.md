# APIClient

`APIClient` is the package's typed REST client layer. Consumers define an `Environment`, describe calls with `Endpoint`, and execute `Request<T>` values through `APIClient.perform`.

## Core Contracts

- `Environment` provides `baseURL` and `shouldAllowInsecureConnections`.
- `Endpoint` provides request path, method, parameters, encoding, headers, timeout and optional upload file.
- `Request<T>` binds an endpoint to a decoder and a response validator.
- `APIClientNetworkFetcher` abstracts network transport so tests can avoid real `URLSession` calls.
- `APIClientDelegate` handles unauthorized responses and receives decoded HTTP errors.
- `MockNetworkFetcher` provides a package test double for configured response data/status and request capture.

## Request Flow

1. `Router` builds a `URLRequest` from `Environment` and `Endpoint`.
2. `APIClient.customizeRequest` can mutate the request, commonly for auth headers.
3. The configured fetcher sends the request or file upload.
4. The response is validated.
5. Data is decoded into the requested `Decodable` type.
6. A `401` can give the delegate one opportunity to refresh auth and retry when the request allows unauthorized retry.

## Request Variants

- `perform(_:)` validates and decodes typed responses.
- `performSimpleRequest(forEndpoint:)` returns the raw `APIClient.Response`.
- File upload uses `Endpoint.fileToUpload` and keeps an iOS background task alive when UIKit is available.
- `setCustomUserAgent(_:)` overrides the generated user-agent string.

## Operational Notes

Logging is configurable for requests and responses. Response errors try to preserve server-provided details, including the `bsw_server_error_message` payload key.

`Environment.shouldAllowInsecureConnections` is used by the session delegate to accept server trust challenges for explicitly insecure environments.

For tests, prefer `MockNetworkFetcher` or an injected `APIClientNetworkFetcher` over live networking.

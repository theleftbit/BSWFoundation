# Parsing

Parsing helpers live under `Sources/BSWFoundation/Parse/` and support the networking layer plus direct consumers.

## JSONParser

`JSONParser` centralizes common JSON operations:

- Detecting literal JSON `null` responses.
- Pretty-printing JSON data for debug output and error messages.
- Extracting `bsw_server_error_message` payloads used by `APIClient.Error`.
- Extracting a generic `"error"` string from JSON data.
- Decoding `Decodable` values with a default ISO-8601 formatter.
- Returning `VoidResponse` for empty typed responses.

When a model conforms to `DateDecodingStrategyProvider`, `JSONParser` uses that formatter instead of the default one. Arrays inherit the formatter when their element type provides one.

## FailableCodableArray

`FailableCodableArray<Element>` decodes arrays while dropping individual elements that fail to decode. Failed elements are logged, but the array can still be consumed through the `elements` property.

Use it when a partially malformed server payload should not discard the whole response.

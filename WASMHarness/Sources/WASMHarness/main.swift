import Foundation
import JavaScriptKit
import JavaScriptEventLoop
import BSWFoundation

@main
struct WASMHarness {
    static func main() {
        JavaScriptEventLoop.installGlobalExecutor()
        Task {
            await runHarness()
            // Tell the node runner (main.mjs) the async work is finished.
            _ = JSObject.global.__harnessDone.function?()
        }
    }
}

private func log(_ message: String) {
    if let console = JSObject.global.console.object {
        _ = console.log!(message)
    }
}

private struct HarnessEnvironment: Environment {
    var baseURL: URL { URL(string: "https://httpbingo.org")! }
}

private enum HarnessAPI: Endpoint {
    case ip
    var path: String { "/ip" }
}

private struct IPResponse: Decodable {
    let origin: String
}

private func runHarness() async {
    log("— BSWFoundation WebAssembly runtime harness —")

    // 1. A real network GET through the default fetcher (FetchNetworkFetcher → JS fetch).
    let client = APIClient(environment: HarnessEnvironment())
    do {
        let request = APIClient.Request<IPResponse>(endpoint: HarnessAPI.ip)
        let ip = try await client.perform(request)
        log("✅ fetch GET https://httpbingo.org/ip → origin = \(ip.origin)")
    } catch {
        log("❌ fetch GET failed: \(error)")
    }

    // 2. A localStorage round-trip through KeychainBacked (→ WASMKeyValueStore → localStorage).
    let token = KeychainBacked(key: "harness.token")
    token.wrappedValue = "hello-from-wasm"
    let readBack = token.wrappedValue
    if readBack == "hello-from-wasm" {
        log("✅ KeychainBacked localStorage round-trip → '\(readBack ?? "")'")
    } else {
        log("❌ KeychainBacked round-trip failed → '\(readBack ?? "nil")'")
    }

    log("— harness complete —")
}

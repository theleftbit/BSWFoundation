//
//  Created by Pierluigi Cifani on 09/02/2017.
//
#if canImport(Testing)
import Testing
import BSWFoundation
import Foundation
import HTTPTypes
#if os(Android)
import FoundationNetworking
#endif

// On WebAssembly the network / URLSession / file / Dispatch based tests are excluded (`#if
// !os(WASI)`); the deterministic, mock-backed tests below run there. Real networking is covered
// by the Apple/Android jobs and by the runtime harness in `WASMHarness/`.

actor APIClientTests {

    var sut: APIClient

    init() {
        #if os(WASI)
        BSWBrowserRuntime.installJavaScriptEventLoop()
        #endif
        sut = APIClient(environment: HTTPBin.Hosts.production)
    }

    #if !os(WASI)
    @Test
    func GET() async throws {
        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

        let _ = try await sut.perform(ipRequest)
    }

    @Test
    func GETWithCustomValidation() async throws {

        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip,
            validator: { response in
                if response.statusCode != 200 {
                    throw ValidationError()
                }
        })

        let _ = try await sut.perform(ipRequest)
    }

    @Test
    func GETCancel() async throws {
        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

        let getTask = Task { try await sut.perform(ipRequest) }
        getTask.cancel()

        do {
            let _ = try await getTask.value
            Issue.record("This should fail here")
        } catch let error {
            if error is CancellationError {
                return
            } else {
                let nsError = error as NSError
                #expect(nsError.domain == NSURLErrorDomain)
                #expect(nsError.code == NSURLErrorCancelled)
            }
        }
    }

    @Test(.disabled(if: isAndroid))
    func upload() async throws {
        let file = try Self.generateRandomFile()
        let uploadRequest = BSWFoundation.APIClient.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(fileURL: file)
        )

        let _ = try await sut.perform(uploadRequest)
        try FileManager.default.removeItem(at: file)
    }

    @Test(.disabled(if: isAndroid))
    func uploadCancel() async throws {
        let file = try Self.generateRandomFile()
        let uploadRequest = BSWFoundation.APIClient.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(fileURL: file)
        )

        let uploadTask = Task { try await sut.perform(uploadRequest) }
        uploadTask.cancel()

        do {
            let _ = try await uploadTask.value
            Issue.record("This should fail here")
        } catch let error {
            if error is CancellationError {

            } else {
                let nsError = error as NSError
                #expect(nsError.domain == NSURLErrorDomain)
                #expect(nsError.code == NSURLErrorCancelled)
            }
        }
        try FileManager.default.removeItem(at: file)
    }
    #endif

    @Test
    func unauthorizedCallsRightMethod() async throws {
        let mockDelegate = await MockAPIClientDelegate()
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: Network401Fetcher())
        sut.delegate = mockDelegate

        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )
        // We don't care about the error here
        let _ = try? await sut.perform(ipRequest)
        let failedPath = await mockDelegate.failedPath
        #expect(failedPath != nil)
    }

    #if !os(WASI)
    @Test
    func unauthorizedRetriesAfterGeneratingNewCredentials() async throws {

        actor MockAPIClientDelegateThatGeneratesNewSignature: APIClientDelegate {

            init(apiClient: APIClient) {
                self.apiClient = apiClient
            }
            let apiClient: APIClient

            func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClientID: APIClient.ID) async throws -> Bool {
                apiClient.customizeRequest = { request in
                    var request = request
                    request.httpRequest.headerFields[.init("JWT")!] = "Daenerys Targaryen is the True Queen"
                    return request
                }
                return true
            }
        }

        final class SignatureCheckingNetworkFetcher: APIClientNetworkFetcher {

            public func perform(_ request: APIClient.OutboundRequest) async throws -> APIClient.Response {
                let isSigned = request.httpRequest.headerFields[.init("JWT")!] != nil
                guard isSigned else {
                    return APIClient.Response(data: Data(), httpResponse: HTTPResponse(status: .init(code: 401)))
                }

                return try await URLSession.shared.perform(request)
            }
        }

        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: SignatureCheckingNetworkFetcher())
        let mockDelegate = MockAPIClientDelegateThatGeneratesNewSignature(apiClient: sut)
        sut.delegate = mockDelegate

        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )
        let _ = try await sut.perform(ipRequest)
    }
    #endif

    @Test
    func customizeRequests() async throws {
        let mockNetworkFetcher = MockNetworkFetcher()
        await mockNetworkFetcher.setMockedData(mockedData: Data())
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: mockNetworkFetcher)
        sut.customizeRequest = {
            var request = $0
            // Exercises the URLRequest-style compatibility shim on OutboundRequest.
            request.setValue("hello", forHTTPHeaderField: "Signature")
            return request
        }

        let ipRequest = BSWFoundation.APIClient.Request<VoidResponse>(
            endpoint: HTTPBin.API.ip
        )

        let _ = try await sut.perform(ipRequest)

        guard let capturedRequest = await mockNetworkFetcher.capturedRequest else {
            throw ValidationError()
        }
        #expect(capturedRequest.httpRequest.headerFields[.init("Signature")!] == "hello")
    }

    @Test
    func customizeSimpleRequests() async throws {
        let mockNetworkFetcher = MockNetworkFetcher()
        await mockNetworkFetcher.setMockedData(mockedData: Data())
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: mockNetworkFetcher)
        sut.customizeRequest = {
            var request = $0
            request.httpRequest.headerFields[.init("Signature")!] = "hello"
            return request
    }

        let _ = try await sut.performSimpleRequest(forEndpoint: HTTPBin.API.ip)

        guard let capturedRequest = await mockNetworkFetcher.capturedRequest else {
            throw ValidationError()
        }
        #expect(capturedRequest.httpRequest.headerFields[.init("Signature")!] == "hello")
    }

    #if !os(WASI)
    static func generateRandomFile() throws -> URL {
        let length = 2048
        let bytes = [UInt32](repeating: 0, count: length).map { _ in arc4random() }
        let data = Data(bytes: bytes, count: length)

        let url = URL.cachesDirectory
            .appending(path: "randomData-\(Int.random(in: 0...10000))")
        try data.write(to: url)

        return url
    }
    #endif
}

@MainActor
private class MockAPIClientDelegate: NSObject, APIClientDelegate {
    func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClientID: APIClient.ID) async throws -> Bool {
        failedPath = atPath
        #if !os(WASI)
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
        return false
    }
    var failedPath: String?
}

private final class Network401Fetcher: APIClientNetworkFetcher {

    public func perform(_ request: APIClient.OutboundRequest) async throws -> APIClient.Response {
        return APIClient.Response(data: Data(), httpResponse: HTTPResponse(status: .init(code: 401)))
    }
}

struct ValidationError: Swift.Error {}

#endif

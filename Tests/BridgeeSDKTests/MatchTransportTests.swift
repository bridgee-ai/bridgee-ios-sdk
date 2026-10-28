import XCTest
@testable import BridgeeSDK

final class MatchTransportTests: XCTestCase {
    func testTransportDoesNotPersistCookiesCredentialsOrResponses() {
        let configuration = MatchTransport.configuration()
        XCTAssertNil(configuration.urlCache)
        XCTAssertNil(configuration.httpCookieStorage)
        XCTAssertNil(configuration.urlCredentialStorage)
        XCTAssertFalse(configuration.httpShouldSetCookies)
        XCTAssertEqual(configuration.requestCachePolicy, .reloadIgnoringLocalCacheData)
    }

    func testRedirectCannotForwardTenantHeaderToAnotherOrigin() {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let source = URL(string: "https://api.bridgee.ai/match")!
        let task = session.dataTask(with: source) // Not resumed: this test performs no network request.
        let response = HTTPURLResponse(url: source, statusCode: 302,
                                       httpVersion: nil, headerFields: ["Location": "https://example.invalid/"])!
        var redirected = URLRequest(url: URL(string: "https://example.invalid/")!)
        redirected.setValue("synthetic-tenant-token", forHTTPHeaderField: "x-tenant-token")
        var completed = false
        MatchRedirectPolicy().urlSession(session, task: task, willPerformHTTPRedirection: response,
                                        newRequest: redirected) { request in
            completed = true
            XCTAssertNil(request)
        }
        XCTAssertTrue(completed)
        task.cancel()
    }
}

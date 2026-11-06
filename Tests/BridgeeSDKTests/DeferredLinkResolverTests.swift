import XCTest
@testable import BridgeeSDK

final class DeferredLinkResolverTests: XCTestCase {
    let link = "https://go.bridgee.app/tenda/offer"
    let prefixes = ["https://go.bridgee.app/tenda/"]
    let origins = ["https://app.example.com"]
    func testRequiresOrganizationBoundaryAndHttps() {
        XCTAssertTrue(DeferredLinkResolver.allowedSource(link, prefixes: prefixes))
        for candidate in ["https://go.bridgee.app/tenda-other/offer", "https://other.example/tenda/offer",
                          "https://go.bridgee.app/tenda/offer?x=1", "https://user@go.bridgee.app/tenda/offer",
                          "https://go.bridgee.app:444/tenda/offer", "http://go.bridgee.app/tenda/offer"] {
            XCTAssertFalse(DeferredLinkResolver.allowedSource(candidate, prefixes: prefixes), candidate)
        }
    }
    func testRequiresExactSourceAndDestinationOrigin() {
        let good = Data("{\"link\":\"\(link)\",\"appLink\":\"https://app.example.com/offer/123\"}".utf8)
        XCTAssertEqual(DeferredLinkResolver.decode(good, source: link, origins: origins)?.appLink, "https://app.example.com/offer/123")
        XCTAssertNil(DeferredLinkResolver.decode(good, source: "https://go.bridgee.app/other/offer", origins: origins))
        XCTAssertNil(DeferredLinkResolver.decode(good, source: link, origins: ["https://foreign.example"]))
        XCTAssertNil(DeferredLinkResolver.decode(Data(repeating: 65, count: 8193), source: link, origins: origins))
        XCTAssertFalse(DeferredLinkResolver.allowedDestination("https://app.example.com.evil.test/", origins: origins))
    }
    func testContentTypeHeaderLookupIsCaseInsensitive() {
        let response = HTTPURLResponse(url: URL(string: link)!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["cOnTeNt-TyPe": "application/vnd.bridgee.deferred+json"])!
        XCTAssertEqual(DeferredLinkResolver.contentType(response), "application/vnd.bridgee.deferred+json")
    }
    func testForeignEvidenceDoesNotRequestNetwork() {
        var completed = false
        DeferredLinkResolver.resolve(blinklink: "https://foreign.example/offer", blinklinkPrefixes: prefixes, appLinkOrigins: origins) {
            XCTAssertNil($0); completed = true
        }
        XCTAssertTrue(completed)
    }
}

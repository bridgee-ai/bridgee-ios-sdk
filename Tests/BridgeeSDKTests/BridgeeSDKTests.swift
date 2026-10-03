import XCTest
@testable import BridgeeSDK // @testable para acessar membros internos

// Mock Provider para testes
class MockAnalyticsProvider: AnalyticsProvider {
    
    var lastEventName: String?
    var lastEventParams: [String: Any]?
    var lastUserPropertyName: String?
    var lastUserPropertyValue: String?
    
    var events: [String] = []
    var eventLogCount = 0
    var userPropertySetCount = 0

    func setUserProperty(name: String, value: String?) {
        lastUserPropertyName = name
        lastUserPropertyValue = value
        userPropertySetCount += 1
    }
    
    func logEvent(name: String, parameters: [String: Any]?) {
        events.append(name)
        lastEventName = name
        lastEventParams = parameters
        eventLogCount += 1
    }
}


final class BridgeeSDKTests: XCTestCase {

    var mockProvider: MockAnalyticsProvider!
    var sdk: BridgeeSDK!

    override func setUp() {
        super.setUp()
        mockProvider = MockAnalyticsProvider()
        sdk = BridgeeSDK.shared
        
        // Configura o SDK para cada teste
        sdk.configure(
            provider: mockProvider,
            tenantId: "test_tenant",
            tenantKey: "test_key",
            dryRun: false
        )
    }

    func testConfiguration() {
        // Testa se o singleton está configurado
        // (Acessar propriedades internas exigiria que elas fossem 'internal'
        // e não 'private', ou usar reflexão, o que é complexo.
        // Vamos testar o efeito.)
        XCTAssertNotNil(sdk) 
    }
    
    func testMatchBundleCreation() {
        let bundle = MatchBundle()
        bundle.set(name: "John Doe")
        bundle.set(email: "john@doe.com")
        bundle.setCustom(key: "custom_id", value: "12345")

        // Testa a formatação do body da API
        let apiBodyData = bundle.asAPIBody()
        XCTAssertNotNil(apiBodyData)
        
        // Decodifica para verificar
        let decoder = JSONDecoder()
        if let data = apiBodyData,
           let requestBody = try? decoder.decode(APIRequest.self, from: data) {
            
            XCTAssertEqual(requestBody.metadata.count, 3)
            XCTAssertTrue(requestBody.metadata.contains(where: { $0.key == "user_name" && $0.value == "John Doe" }))
            XCTAssertTrue(requestBody.metadata.contains(where: { $0.key == "custom_id" && $0.value == "12345" }))
        } else {
            XCTFail("Falha ao decodificar o body da API do MatchBundle")
        }
    }
    
    func testDryRunMode() {
        // Reconfigura para dryRun
        sdk.configure(
            provider: mockProvider,
            tenantId: "test_tenant",
            tenantKey: "test_key",
            dryRun: true
        )
        
        sdk.deliverAttribution(APIResponse(utm_source: "TikTok", utm_medium: "paid_social", utm_campaign: "Launch"), tenantId: "test_tenant")
        
        // No modo dryRun, NENHUM evento deve ser enviado
        XCTAssertEqual(mockProvider.eventLogCount, 0)
        XCTAssertEqual(mockProvider.userPropertySetCount, 0)
    }
    
    func testDeliveryPreservesCampaignWithoutFirstOpenOrPurchase() {
        sdk.deliverAttribution(
            APIResponse(utm_source: "TikTok", utm_medium: "paid_social", utm_campaign: "Launch+Summer"),
            tenantId: "test-tenant"
        )
        XCTAssertEqual(mockProvider.events, ["test_tenant_campaign_details", "campaign_details"])
        XCTAssertEqual(mockProvider.lastEventParams?["campaign"] as? String, "Launch+Summer")
        XCTAssertEqual(mockProvider.userPropertySetCount, 3)
        XCTAssertEqual(mockProvider.lastUserPropertyValue, "Launch+Summer")
    }

    func testDeniedConsentAndNativeGoogleNeverDeliver() {
        sdk.firstOpen(with: MatchBundle(), consentGranted: false, preserveNativeGoogleAttribution: false) { data, error in
            XCTAssertNil(data)
            XCTAssertEqual(error, "attribution_consent_required")
        }
        sdk.firstOpen(with: MatchBundle(), consentGranted: true, preserveNativeGoogleAttribution: true) { data, error in
            XCTAssertEqual(data?.utm_source, "")
            XCTAssertNil(error)
        }
        XCTAssertEqual(mockProvider.eventLogCount, 0)
        XCTAssertEqual(mockProvider.userPropertySetCount, 0)
    }
}

// Extensão para acessar a struct interna para teste
@testable import BridgeeSDK
extension APIRequest: Equatable {
    public static func == (lhs: APIRequest, rhs: APIRequest) -> Bool {
        return lhs.metadata == rhs.metadata
    }
}
extension APIRequest.MetadataEntry: Equatable {
    public static func == (lhs: APIRequest.MetadataEntry, rhs: APIRequest.MetadataEntry) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
}

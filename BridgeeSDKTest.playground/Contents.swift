import UIKit
import PlaygroundSupport

// Este playground pode ser usado para testar o SDK
// Nota: Você precisará adicionar o SDK como dependência do playground

// Mock Analytics Provider para teste
class MockAnalyticsProvider: AnalyticsProvider {
    var events: [(name: String, parameters: [String: Any]?)] = []
    var userProperties: [(name: String, value: String?)] = []
    
    func setUserProperty(name: String, value: String?) {
        userProperties.append((name: name, value: value))
        print("📊 User Property Set: \(name) = \(value ?? "nil")")
    }
    
    func logEvent(name: String, parameters: [String: Any]?) {
        events.append((name: name, parameters: parameters))
        print("🎯 Event Logged: \(name)")
        if let params = parameters {
            print("   Parameters: \(params)")
        }
    }
}

// Teste básico do SDK
func testBridgeeSDK() {
    let mockProvider = MockAnalyticsProvider()
    
    // Configurar SDK em modo dry run
    BridgeeSDK.shared.configure(
        provider: mockProvider,
        tenantId: "test_tenant",
        tenantKey: "test_key",
        dryRun: true
    )
    
    // Criar match bundle
    var bundle = MatchBundle()
    bundle.set(name: "João Teste")
    bundle.set(email: "joao@teste.com")
    bundle.setCustom(key: "test_id", value: "12345")
    
    // Processar primeiro evento (em modo dry run)
    Task {
        let utmData = await BridgeeSDK.shared.firstOpen(with: bundle)
        
        print("\n✅ Teste concluído!")
        
        // Testar retorno de dados UTM
        if let utm = utmData {
            print("🎯 Dados UTM retornados:")
            print("   - utm_source: \(utm.utm_source)")
            print("   - utm_medium: \(utm.utm_medium)")
            print("   - utm_campaign: \(utm.utm_campaign)")
        } else {
            print("❌ Nenhum dado UTM retornado")
        }
        
        print("📊 User Properties definidas: \(mockProvider.userProperties.count)")
        print("🎯 Eventos registrados: \(mockProvider.events.count)")
        
        // Teste adicional em modo normal (não dry-run)
        print("\n🔄 Testando modo normal...")
        BridgeeSDK.shared.configure(
            provider: mockProvider,
            tenantId: "test_tenant",
            tenantKey: "test_key",
            dryRun: false
        )
        
        let utmDataNormal = await BridgeeSDK.shared.firstOpen(with: bundle)
        if let utm = utmDataNormal {
            print("✅ Modo normal - Dados UTM retornados:")
            print("   - utm_source: \(utm.utm_source)")
            print("   - utm_medium: \(utm.utm_medium)")
            print("   - utm_campaign: \(utm.utm_campaign)")
        }
    }
}

// Executar teste
testBridgeeSDK()

// Manter o playground ativo
PlaygroundPage.current.needsIndefiniteExecution = true

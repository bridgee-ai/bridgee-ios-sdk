import UIKit
import BridgeeSDK

// IMPORTANTE: Firebase deve ser adicionado como dependência do SEU APP, não do SDK
// Adicione ao Package.swift do seu app:
// .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")

import FirebaseAnalytics

// MARK: - Implementação do AnalyticsProvider usando Firebase
class FirebaseAnalyticsProvider: AnalyticsProvider {
    func setUserProperty(name: String, value: String?) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    func logEvent(name: String, parameters: [String: Any]?) {
        Analytics.logEvent(name, parameters: parameters)
    }
}

// MARK: - Exemplo de uso no AppDelegate
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. Configurar Firebase (necessário antes do BridgeeSDK)
        FirebaseApp.configure()
        
        // 2. Criar o provider de analytics
        let analyticsProvider = FirebaseAnalyticsProvider()
        
        // 3. Configurar o BridgeeSDK
        BridgeeSDK.shared.configure(
            provider: analyticsProvider,
            tenantId: "seu_tenant_id_aqui",
            tenantKey: "sua_tenant_key_aqui",
            dryRun: false // Mude para true durante desenvolvimento
        )
        
        return true
    }
}

// MARK: - Exemplo de uso em um ViewController
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Simular primeiro evento de abertura após o usuário fazer login
        // ou fornecer dados de identificação
        handleFirstOpen()
    }
    
    private func handleFirstOpen() {
        // Criar bundle com dados do usuário
        var matchBundle = MatchBundle()
        
        // Dados básicos do usuário
        matchBundle.set(name: "João Silva")
        matchBundle.set(email: "joao.silva@exemplo.com")
        matchBundle.set(phone: "+5511999999999")
        
        // Google Click ID (se disponível)
        if let gclid = getGoogleClickId() {
            matchBundle.set(gclid: gclid)
        }
        
        // Dados customizados
        matchBundle.setCustom(key: "user_id", value: "12345")
        matchBundle.setCustom(key: "signup_source", value: "app_store")
        
        // Processar primeiro evento de abertura (compatível com iOS 14.0+)
        BridgeeSDK.shared.firstOpen(with: matchBundle) { [weak self] utmData in
            // Usar os dados UTM retornados
            if let utm = utmData {
                print("📊 Dados UTM obtidos:")
                print("  - Source: \(utm.utm_source)")
                print("  - Medium: \(utm.utm_medium)")
                print("  - Campaign: \(utm.utm_campaign)")
                
                // Você pode usar esses dados para personalizar a experiência do usuário
                // Por exemplo, mostrar uma mensagem de boas-vindas específica da campanha
                DispatchQueue.main.async {
                    self?.showWelcomeMessage(for: utm)
                }
            } else {
                print("⚠️ Nenhum dado UTM foi retornado")
            }
        }
    }
    
    // Exemplo de função para obter Google Click ID
    private func getGoogleClickId() -> String? {
        // Implementar lógica para obter GCLID
        // Por exemplo, de deep links, UserDefaults, etc.
        return UserDefaults.standard.string(forKey: "gclid")
    }
    
    // Exemplo de função para mostrar mensagem personalizada baseada nos dados UTM
    private func showWelcomeMessage(for utmData: UTMData) {
        let message = "Bem-vindo! Você chegou através de: \(utmData.utm_source)"
        
        let alert = UIAlertController(
            title: "Bem-vindo!",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
}

// MARK: - Exemplo de uso com SwiftUI
import SwiftUI

@available(iOS 14.0, *)
struct ContentView: View {
    @State private var isProcessingFirstOpen = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("BridgeeSDK Example")
                .font(.title)
            
            Button("Processar Primeiro Evento") {
                processFirstOpen()
            }
            .disabled(isProcessingFirstOpen)
            
            if isProcessingFirstOpen {
                ProgressView("Processando...")
            }
        }
        .padding()
    }
    
    private func processFirstOpen() {
        isProcessingFirstOpen = true
        
        var matchBundle = MatchBundle()
        matchBundle.set(name: "Maria Santos")
        matchBundle.set(email: "maria@exemplo.com")
        matchBundle.setCustom(key: "platform", value: "ios")
        
        BridgeeSDK.shared.firstOpen(with: matchBundle) { utmData in
            DispatchQueue.main.async {
                isProcessingFirstOpen = false
                
                if let utm = utmData {
                    print("📊 SwiftUI - Dados UTM obtidos:")
                    print("  - Source: \(utm.utm_source)")
                    print("  - Medium: \(utm.utm_medium)")
                    print("  - Campaign: \(utm.utm_campaign)")
                }
            }
        }
    }
}

// MARK: - Exemplo de tratamento de Deep Links
extension AppDelegate {
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // Extrair parâmetros de campanha do deep link
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            
            // Salvar GCLID se presente
            if let gclid = queryItems.first(where: { $0.name == "gclid" })?.value {
                UserDefaults.standard.set(gclid, forKey: "gclid")
            }
            
            // Outros parâmetros UTM podem ser salvos aqui também
        }
        
        return true
    }
}

// MARK: - Exemplo de configuração para diferentes ambientes
extension BridgeeSDK {
    
    static func configureForEnvironment() {
        let analyticsProvider = FirebaseAnalyticsProvider()
        
        #if DEBUG
        // Configuração para desenvolvimento
        BridgeeSDK.shared.configure(
            provider: analyticsProvider,
            tenantId: "dev_tenant_id",
            tenantKey: "dev_tenant_key",
            dryRun: true // Modo dry run para desenvolvimento
        )
        #else
        // Configuração para produção
        BridgeeSDK.shared.configure(
            provider: analyticsProvider,
            tenantId: "prod_tenant_id",
            tenantKey: "prod_tenant_key",
            dryRun: false
        )
        #endif
    }
}

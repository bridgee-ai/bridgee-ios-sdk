# Bridgee iOS SDK

[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-compatible-red.svg)](https://cocoapods.org/)
[![iOS](https://img.shields.io/badge/iOS-14.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.5%2B-orange.svg)](https://swift.org/)

## 📖 Visão Geral

O **Bridgee iOS SDK** é uma solução completa de atribuição que conecta suas campanhas de marketing aos eventos de instalação e primeira abertura do seu aplicativo iOS. Ele resolve o problema de atribuição precisa em campanhas de aquisição de usuários, integrando-se perfeitamente com provedores de analytics como Firebase Analytics.

### 🎯 Principais Funcionalidades

- **Atribuição Precisa**: Conecta cliques em campanhas com instalações reais
- **Múltiplas Opções de Instalação**: Swift Package Manager e CocoaPods
- **Integração Flexível**: Funciona com qualquer provedor de analytics
- **Callbacks Assíncronos**: Receba dados de atribuição em tempo real
- **Atribuição de Sessão Automática**: O SDK cuida da comunicação com seu provedor de analytics para associar a sessão do usuário ao canal de aquisição
- **Privacy Manifest**: Conformidade total com as diretrizes da Apple

---

## 🚀 Instalação

### Swift Package Manager (Recomendado)

Adicione a dependência no Xcode:

1. **File → Add Package Dependencies**
2. Digite a URL do repositório: `https://github.com/bridgee-ai/bridgee-ios-sdk.git`
3. Selecione a versão desejada

Ou adicione ao seu `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bridgee-ai/bridgee-ios-sdk.git", from: "1.0.0")
]
```

### CocoaPods

Adicione ao seu `Podfile`:

```ruby
pod 'BridgeeSDK', '~> 1.0'
```

Em seguida, execute:

```bash
pod install
```

---

## 📱 Exemplo de Uso

Para ver uma implementação completa e funcional do Bridgee iOS SDK, confira nosso **repositório de exemplo**:

🔗 **[Bridgee iOS Example App](https://github.com/bridgee-ai/bridgee-ios-example)**

O exemplo inclui:
- Configuração completa do SDK com Firebase Analytics
- Interface de usuário para testar diferentes cenários
- Implementação de boas práticas
- Casos de uso reais de atribuição

---

## 🔧 Configuração Rápida

### 1. Implementar AnalyticsProvider

Primeiro, crie uma implementação do `AnalyticsProvider` para seu provedor de analytics:

```swift
// Para Firebase Analytics
import FirebaseAnalytics
import BridgeeSDK

class FirebaseAnalyticsProvider: AnalyticsProvider {
    func setUserProperty(name: String, value: String?) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    func logEvent(name: String, parameters: [String: Any]?) {
        Analytics.logEvent(name, parameters: parameters)
    }
}
```

### 2. Inicializar o SDK

```swift
import SwiftUI
import FirebaseCore
import BridgeeSDK

@main
struct MyApp: App {
    init() {
        // Configurar Firebase
        FirebaseApp.configure()
        
        // Configurar o Bridgee SDK
        BridgeeSDK.shared.configure(
            provider: FirebaseAnalyticsProvider(),
            tenantId: "seu_tenant_id",        // Tenant ID fornecido pela Bridgee
            tenantKey: "sua_tenant_key",      // Tenant Key fornecida pela Bridgee
            dryRun: false                     // false para produção
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. Registrar Primeira Abertura

No evento de primeira abertura do app:

```swift
import BridgeeSDK

class ContentView: View {
    var body: some View {
        VStack {
            Button("Simular First Open") {
                trackFirstOpen()
            }
        }
    }
    
    private func trackFirstOpen() {
        // Versão simples
        let matchBundle = MatchBundle()
        
        BridgeeSDK.shared.firstOpen(with: matchBundle) { utmData in
            if let utmData = utmData {
                print("✅ Atribuição resolvida:")
                print("📊 Source: \(utmData.utm_source ?? "nil")")
                print("📱 Medium: \(utmData.utm_medium ?? "nil")")
                print("🎯 Campaign: \(utmData.utm_campaign ?? "nil")")
            } else {
                print("❌ Erro na atribuição")
            }
        }
    }
}
```

> 💡 **Projeto de Exemplo Completo**: Confira o [bridgee-ios-example](https://github.com/bridgee-ai/bridgee-ios-example) para ver uma implementação completa com interface de usuário e tratamento de callbacks.

---

## 📚 Guia Detalhado

### MatchBundle — Opcional, mas recomendado

**Todos os campos do `MatchBundle` são opcionais.** O SDK consegue resolver a atribuição mesmo com um bundle vazio, usando sinais de dispositivo e rede (fingerprint) para reconciliar com o clique original. No entanto, **quanto mais dados você fornecer, maior a confiança do match** — especialmente em cenários de alto volume ou com múltiplos usuários compartilhando a mesma rede (Wi-Fi corporativo, NAT, etc.).

```swift
// Bundle vazio — funciona, mas com confiança menor
BridgeeSDK.shared.firstOpen(with: MatchBundle()) { utmData in
    // Processar resultado
}

// Bundle enriquecido — maior confiança no match
var matchBundle = MatchBundle()
matchBundle.set(name: "João Silva")              // Nome do usuário
matchBundle.set(email: "usuario@email.com")      // Email do usuário
matchBundle.set(phone: "+5511999999999")         // Telefone do usuário
matchBundle.set(gclid: "gclid_value")           // Google Click ID
matchBundle.setCustom(key: "user_id", value: "123") // Parâmetros customizados

BridgeeSDK.shared.firstOpen(with: matchBundle) { utmData in
    // Processar resultado
}
```

> 🔗 **Propague os mesmos sinais nos blinks.** Para que a reconciliação seja máxima, os parâmetros enviados ao `firstOpen()` devem também estar presentes nas URLs de captura (os **blinks**, ex.: `https://ios.seuapp.com.br/?email=...&phone=...&utm_source=...`). O servidor Bridgee compara os sinais dos dois lados (clique vs. instalação) — quanto maior a interseção, mais eficiente e preciso o match.

### Atribuição Automática da Sessão

Quando a atribuição é resolvida, o SDK se encarrega de comunicar os dados de aquisição ao seu provedor de analytics (Firebase, Amplitude, etc.), garantindo que toda a sessão do usuário fique associada ao canal de origem — sem necessidade de tratamento manual no código do app.

---

## 🔍 Exemplo Completo

```swift
import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import BridgeeSDK

class BridgeeManager {
    static let shared = BridgeeManager()
    private let tag = "BridgeeManager"
    
    private init() {}
    
    func initialize() {
        let provider = FirebaseAnalyticsProvider()
        
        BridgeeSDK.shared.configure(
            provider: provider,
            tenantId: "your_tenant_id",
            tenantKey: "your_tenant_key",
            dryRun: false
        )
    }
    
    func trackFirstOpen(name: String?, email: String?, phone: String?) {
        var matchBundle = MatchBundle()
        
        if let name = name, !name.isEmpty {
            matchBundle.set(name: name)
        }
        
        if let email = email, !email.isEmpty {
            matchBundle.set(email: email)
        }
        
        if let phone = phone, !phone.isEmpty {
            matchBundle.set(phone: phone)
        }
        
        // Adicionar versão do app como parâmetro customizado
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            matchBundle.setCustom(key: "app_version", value: version)
        }
        
        BridgeeSDK.shared.firstOpen(with: matchBundle) { [weak self] utmData in
            DispatchQueue.main.async {
                if let utmData = utmData {
                    print("✅ Atribuição bem-sucedida!")
                    print("📊 UTM Source: \(utmData.utm_source ?? "nil")")
                    print("📱 UTM Medium: \(utmData.utm_medium ?? "nil")")
                    print("🎯 UTM Campaign: \(utmData.utm_campaign ?? "nil")")
                    
                    // Aqui você pode executar lógica adicional baseada na atribuição
                    self?.handleAttributionSuccess(utmData)
                } else {
                    print("❌ Erro na atribuição")
                    
                    // Implementar fallback ou retry se necessário
                    self?.handleAttributionError()
                }
            }
        }
    }
    
    private func handleAttributionSuccess(_ utmData: UTMData) {
        // Implementar lógica específica do app
    }
    
    private func handleAttributionError() {
        // Implementar tratamento de erro
    }
}

// Uso no App
@main
struct MyApp: App {
    init() {
        FirebaseApp.configure()
        BridgeeManager.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## ⚙️ Configuração Avançada

### Modo Dry Run

Para testes, você pode habilitar o modo dry run:

```swift
BridgeeSDK.shared.configure(
    provider: provider,
    tenantId: "test_tenant",
    tenantKey: "test_key",
    dryRun: true
)
```

No modo dry run, o SDK:
- ✅ Executa toda a lógica de atribuição
- ✅ Gera logs detalhados
- ✅ Faz chamadas à API
- ❌ **NÃO** envia eventos para o analytics provider

### Configuração via Info.plist

```xml
<!-- No Info.plist -->
<key>BridgeeTenantId</key>
<string>$(BRIDGEE_TENANT_ID)</string>
<key>BridgeeTenantKey</key>
<string>$(BRIDGEE_TENANT_KEY)</string>
<key>BridgeeDryRun</key>
<false/>

<!-- No código -->
let tenantId = Bundle.main.object(forInfoDictionaryKey: "BridgeeTenantId") as? String ?? ""
let tenantKey = Bundle.main.object(forInfoDictionaryKey: "BridgeeTenantKey") as? String ?? ""
let dryRun = Bundle.main.object(forInfoDictionaryKey: "BridgeeDryRun") as? Bool ?? false

BridgeeSDK.shared.configure(
    provider: provider,
    tenantId: tenantId,
    tenantKey: tenantKey,
    dryRun: dryRun
)
```

---

## 📋 Requisitos

- **iOS**: 14.0+
- **Xcode**: 13.0+
- **Swift**: 5.5+
- **Dependências**: Nenhuma (completamente desacoplado)

---

## 🐛 Troubleshooting

### Problemas Comuns

**1. SDK não configurado**
```
Erro: "SDK não configurado. Chame BridgeeSDK.shared.configure() primeiro."
Solução: Verifique se configure() foi chamado antes de firstOpen()
```

**2. Eventos não aparecem no Firebase**
```
Solução: Verifique se o modo dry run está desabilitado em produção
```

**3. Callback não é executado**
```
Solução: Verifique a conectividade de rede e as credenciais do tenant
```

### Logs de Debug

Para habilitar logs detalhados, procure por `[BRIDGEE-SDK]` no console do Xcode:

```bash
# No simulador ou device
Console.app → Filtrar por "BRIDGEE-SDK"
```

---

## 🔗 Links Úteis

- 📱 [Exemplo de Implementação](https://github.com/bridgee-ai/bridgee-ios-example) - Implementação completa com UI
- 📦 [CocoaPods](https://cocoapods.org/pods/BridgeeAiSDK)
- 🤖 [Bridgee Android SDK](https://github.com/bridgee-ai/bridgee-android-sdk)
- ⚛️ [Bridgee React Native SDK](https://github.com/bridgee-ai/bridgee-react-native-sdk)
- 🐛 [Reportar Issues](https://github.com/bridgee-ai/bridgee-ios-sdk/issues)
- 💬 [Suporte Técnico](mailto:support@bridgee.ai)


---

**Desenvolvido com ❤️ pela equipe Bridgee.ai**

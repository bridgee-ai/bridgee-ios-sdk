import Foundation

/// Estrutura para retornar os dados UTM obtidos da API
public struct UTMData {
    public let utm_source: String
    public let utm_medium: String
    public let utm_campaign: String
    
    public init(utm_source: String, utm_medium: String, utm_campaign: String) {
        self.utm_source = utm_source
        self.utm_medium = utm_medium
        self.utm_campaign = utm_campaign
    }
}

/// A classe principal e ponto de entrada para o BridgeeSDK.
@available(iOS 14.0, *)
public final class BridgeeSDK {

    // 1. Implementação do Singleton
    public static let shared = BridgeeSDK()
    private init() {} // Construtor privado para forçar o singleton

    // 2. Propriedades Internas
    private var provider: AnalyticsProvider?
    private var tenantId: String?
    private var tenantToken: String? // O token em base64
    private var dryRun: Bool = false
    private let apiBaseURL = "https://api.bridgee.ai/match"
    
    // Prefixo para logs internos
    private let logPrefix = "[BridgeeSDK]"

    // 3. Método de Configuração (Constructor)
    /// Configura a instância singleton do SDK.
    /// Chame este método na inicialização do aplicativo.
    /// - Parameters:
    ///   - provider: A implementação do AnalyticsProvider fornecida pelo cliente.
    ///   - tenantId: Seu ID de tenant fornecido pela Bridgee.
    ///   - tenantKey: Sua chave de tenant fornecida pela Bridgee.
    ///   - dryRun: Se true, o SDK registrará no console em vez de enviar eventos.
    public func configure(
        provider: AnalyticsProvider,
        tenantId: String,
        tenantKey: String,
        dryRun: Bool = false
    ) {
        self.provider = provider
        self.tenantId = tenantId
        self.dryRun = dryRun
        
        // Monta o tenant-token (Base64)
        let tokenString = "\(tenantId);\(tenantKey)"
        if let tokenData = tokenString.data(using: .utf8) {
            self.tenantToken = tokenData.base64EncodedString()
        } else {
            print("\(logPrefix) ERRO: Falha ao codificar o tenant-token. O SDK não funcionará.")
        }
        
        print("\(logPrefix) BridgeeSDK configurado. Modo DryRun: \(dryRun)")
    }

    // 4. Método Público: firstOpen (compatível com iOS 14.0+)
    /// Processa o primeiro evento de abertura, aciona a API de match
    /// e registra os eventos de atribuição usando completion handler.
    /// - Parameters:
    ///   - matchBundle: O pacote de dados do usuário.
    ///   - completion: Callback com UTMData ou nil em caso de erro
    public func firstOpen(with matchBundle: MatchBundle, completion: @escaping (UTMData?) -> Void) {
        print("\(logPrefix) firstOpen iniciado (iOS 14.0+ compatible).")
        
        // Verificações de configuração
        guard let tenantId = self.tenantId else {
            print("\(logPrefix) ERRO: SDK não configurado. Chame BridgeeSDK.shared.configure() primeiro.")
            completion(nil)
            return
        }
        
        guard let tenantToken = self.tenantToken else {
            print("\(logPrefix) ERRO: Tenant Token é inválido ou nulo. Verifique tenantId e tenantKey.")
            completion(nil)
            return
        }
        
        // Fazer chamada à API usando completion handler
        performMatchRequest(bundle: matchBundle, token: tenantToken) { [weak self] result in
            guard let self = self else {
                completion(nil)
                return
            }
            
            switch result {
            case .success(let response):
                print("\(self.logPrefix) API de Match retornou com sucesso.")
                
                // Criar objeto UTMData para retorno
                let utmData = UTMData(
                    utm_source: response.utm_source,
                    utm_medium: response.utm_medium,
                    utm_campaign: response.utm_campaign
                )
                
                // Verificação de dryRun - agora após obter dados da API
                if self.dryRun {
                    print("\(self.logPrefix) [DRY RUN] SDK em modo dry run. Eventos e atributos não serão enviados.")
                    print("\(self.logPrefix) [DRY RUN] MatchBundle recebido: \(String(describing: matchBundle))")
                    print("\(self.logPrefix) [DRY RUN] Dados UTM obtidos da API:")
                    print("\(self.logPrefix) [DRY RUN]   - utm_source: \(response.utm_source)")
                    print("\(self.logPrefix) [DRY RUN]   - utm_medium: \(response.utm_medium)")
                    print("\(self.logPrefix) [DRY RUN]   - utm_campaign: \(response.utm_campaign)")
                    print("\(self.logPrefix) [DRY RUN] Eventos que seriam enviados para: \(tenantId)")
                    completion(utmData)
                    return
                }
                
                // Verificar se provider está disponível (apenas necessário quando não é dry run)
                guard let provider = self.provider else {
                    print("\(self.logPrefix) ERRO: Provider não configurado. Chame BridgeeSDK.shared.configure() primeiro.")
                    completion(utmData) // Retorna os dados mesmo sem provider
                    return
                }
                
                // Parâmetros comuns para eventos
                let eventParams: [String: Any] = [
                    "utm_source": response.utm_source,
                    "utm_medium": response.utm_medium,
                    "utm_campaign": response.utm_campaign,
                    "source": response.utm_source, // duplicado conforme solicitado
                    "medium": response.utm_medium, // duplicado conforme solicitado
                    "campaign": response.utm_campaign // duplicado conforme solicitado
                ]

                // Enviar eventos para o FirebaseAnalytics
                let sanitizedTenantId = tenantId.replacingOccurrences(of: "-", with: "_")
                provider.logEvent(name: "\(sanitizedTenantId)_first_open", parameters: eventParams)
                provider.logEvent(name: "\(sanitizedTenantId)_campaign_details", parameters: eventParams)
                provider.logEvent(name: "first_open", parameters: eventParams)
                provider.logEvent(name: "campaign_details", parameters: eventParams)
                
                print("\(self.logPrefix) 4 eventos de atribuição registrados via provider.")

                // Gravar propriedades do usuário
                provider.setUserProperty(name: "install_source", value: response.utm_source)
                provider.setUserProperty(name: "install_medium", value: response.utm_medium)
                provider.setUserProperty(name: "install_campaign", value: response.utm_campaign)
                
                print("\(self.logPrefix) 3 propriedades de usuário de instalação registradas via provider.")
                
                completion(utmData)
                
            case .failure(let error):
                print("\(self.logPrefix) ERRO: Falha no processo de firstOpen: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    // 5a. Lógica de Rede Interna (compatível com iOS 14.0+)
    private func performMatchRequest(bundle: MatchBundle, token: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let url = URL(string: apiBaseURL) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "x-tenant-token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bundle.asAPIBody()
        
        print("\(logPrefix) Iniciando chamada de rede para \(url.absoluteString)")

        // Usa URLSession nativo com completion handler (compatível com iOS 14.0+)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                completion(.failure(APIError.networkError(URLError(.unknown))))
                return
            }
            
            if let error = error {
                completion(.failure(APIError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.networkError(URLError(.badServerResponse))))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("\(self.logPrefix) ERRO: Erro do servidor: Status Code \(httpResponse.statusCode)")
                completion(.failure(APIError.serverError(statusCode: httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.networkError(URLError(.badServerResponse))))
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(.success(apiResponse))
            } catch {
                print("\(self.logPrefix) ERRO: Falha ao decodificar resposta JSON: \(error.localizedDescription)")
                completion(.failure(APIError.decodingError(error)))
            }
        }.resume()
    }
}

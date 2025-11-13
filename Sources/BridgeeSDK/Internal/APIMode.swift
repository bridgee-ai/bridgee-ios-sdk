import Foundation

// Estrutura interna para o corpo da solicitação (Request Body)
internal struct APIRequest: Codable {
    let metadata: [MetadataEntry]

    struct MetadataEntry: Codable {
        let key: String
        let value: String
    }
}

// Estrutura interna para a resposta da API (Response Payload)
internal struct APIResponse: Codable {
    let utm_source: String
    let utm_medium: String
    let utm_campaign: String
}

// Estrutura interna para erros da API
internal enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int)
    case notFound // Caso especial para 404 - não deve gerar erro
    case unconfigured
    case missingTenantToken
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL. Please check SDK configuration."
        case .networkError(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "No internet connection. Please check your connectivity."
                case .timedOut:
                    return "Request timeout. Please try again."
                case .cannotFindHost, .cannotConnectToHost:
                    return "Cannot connect to server. Please check your connection."
                default:
                    return "Network error: \(urlError.localizedDescription)"
                }
            }
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Error processing server response. Please try again."
        case .serverError(let statusCode):
            switch statusCode {
            case 401:
                return "Invalid credentials. Please check your tenantId and tenantKey."
            case 400, 402...499:
                return "Bad request calling bridgee.api - please contact support"
            case 500...599:
                return "Bridgee server error - please contact support"
            default:
                return "Server error (code \(statusCode)). Please try again."
            }
        case .notFound:
            return "Attribution data not found. Returning empty UTM data."
        case .unconfigured:
            return "SDK not configured. Call BridgeeSDK.shared.configure() first."
        case .missingTenantToken:
            return "Invalid authentication token. Please check your credentials."
        }
    }
}

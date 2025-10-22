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
internal enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int)
    case unconfigured
    case missingTenantToken
}

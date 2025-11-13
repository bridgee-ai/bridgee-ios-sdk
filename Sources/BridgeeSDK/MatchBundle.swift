import Foundation

/// Um contêiner para dados de identificação do usuário
/// a serem enviados para o backend de match.
@objc
public class MatchBundle: NSObject {
    // Usa um dicionário interno para armazenar os pares de chave-valor.
    private var metadata: [String: String] = [:]

    /// Adiciona um par de chave-valor personalizado.
    public func setCustom(key: String, value: String) {
        metadata[key] = value
    }

    /// Define o nome do usuário.
    public func set(name: String) {
        metadata["user_name"] = name
    }

    /// Define o e-mail do usuário.
    public func set(email: String) {
        metadata["user_email"] = email
    }

    /// Define o telefone do usuário.
    public func set(phone: String) {
        metadata["user_phone"] = phone
    }

    /// Define o Google Click ID (gclid).
    public func set(gclid: String) {
        metadata["gclid"] = gclid
    }
    
    // Função interna para formatar os dados para a API
    // Conforme o contrato: {"metadata": [{"key": "...", "value": "..."}]}
    internal func asAPIBody() -> Data? {
        let apiMetadata = metadata.map { APIRequest.MetadataEntry(key: $0.key, value: $0.value) }
        let requestBody = APIRequest(metadata: apiMetadata)
        return try? JSONEncoder().encode(requestBody)
    }
}
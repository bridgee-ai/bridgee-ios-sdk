import Foundation

/// Um protocolo implementado pelo aplicativo cliente para fornecer
/// uma ponte para sua instância do Firebase Analytics.
public protocol AnalyticsProvider {
    /// Define uma propriedade de usuário no Firebase Analytics.
    /// - Parameters:
    ///   - name: O nome da propriedade.
    ///   - value: O valor da propriedade.
    func setUserProperty(name: String, value: String?)

    /// Registra um evento no Firebase Analytics.
    /// - Parameters:
    ///   - name: O nome do evento.
    ///   - parameters: Um dicionário de parâmetros do evento.
    func logEvent(name: String, parameters: [String: Any]?)
}

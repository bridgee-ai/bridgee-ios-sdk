import Foundation

public struct DeferredDestination: Equatable {
    public let blinklink: String
    public let appLink: String
}

/// Resolve explicit evidence from an app-owned continuation. This does not recover an App Store install automatically.
/// No fingerprinting, clipboard access, navigation, or analytics.
public enum DeferredLinkResolver {
    static func https(_ value: String) -> URL? {
        guard value.utf8.count <= 2048, let url = URL(string: value),
              url.scheme == "https", url.host != nil, url.user == nil, url.password == nil,
              url.port == nil || url.port == 443 else { return nil }
        return url
    }
    static func sameOrigin(_ a: URL, _ b: URL) -> Bool { a.host?.lowercased() == b.host?.lowercased() }
    static func allowedSource(_ value: String, prefixes: [String]) -> Bool {
        guard let link = https(value), link.query == nil, link.fragment == nil else { return false }
        return prefixes.contains { value in
            guard let prefix = https(value), prefix.query == nil, prefix.fragment == nil,
                  value.hasSuffix("/") else { return false }
            let path = prefix.path.hasSuffix("/") ? prefix.path : prefix.path + "/"
            return sameOrigin(link, prefix) && link.path.hasPrefix(path)
        }
    }
    static func allowedDestination(_ value: String, origins: [String]) -> Bool {
        guard let link = https(value) else { return false }
        return origins.contains { value in
            guard let origin = https(value), origin.path.isEmpty || origin.path == "/",
                  origin.query == nil, origin.fragment == nil else { return false }
            return sameOrigin(link, origin)
        }
    }
    static func decode(_ data: Data, source: String, origins: [String]) -> DeferredDestination? {
        guard data.count <= 8192,
              let payload = try? JSONDecoder().decode(Payload.self, from: data),
              payload.link == source, payload.appLink != source,
              allowedDestination(payload.appLink, origins: origins) else { return nil }
        return DeferredDestination(blinklink: source, appLink: payload.appLink)
    }
    private struct Payload: Decodable { let link: String; let appLink: String }
    // Keep SwiftPM host compilation compatible with its default macOS deployment target.
    // HTTPURLResponse.value(forHTTPHeaderField:) requires macOS 10.15.
    static func contentType(_ response: HTTPURLResponse) -> String? {
        response.allHeaderFields.first { String(describing: $0.key).lowercased() == "content-type" }?.value as? String
    }

    /// Completion runs on the URLSession callback queue. The app owns successful-navigation persistence.
    public static func resolve(blinklink: String, blinklinkPrefixes: [String], appLinkOrigins: [String],
                               completion: @escaping (DeferredDestination?) -> Void) {
        guard allowedSource(blinklink, prefixes: blinklinkPrefixes), !appLinkOrigins.isEmpty else {
            completion(nil); return
        }
        var endpoint = URLComponents(string: "https://api.bridgee.ai/deferred")!
        endpoint.queryItems = [URLQueryItem(name: "platform", value: "ios"), URLQueryItem(name: "link", value: blinklink)]
        let endpointURL = endpoint.url!
        let config = MatchTransport.configuration()
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 8
        let session = URLSession(configuration: config, delegate: MatchRedirectPolicy(), delegateQueue: nil)
        var request = URLRequest(url: endpointURL)
        request.setValue("application/vnd.bridgee.deferred+json", forHTTPHeaderField: "Accept")
        session.dataTask(with: request) { data, response, error in
            defer { session.finishTasksAndInvalidate() }
            guard error == nil, let response = response as? HTTPURLResponse, response.statusCode == 200,
                  response.url == endpointURL,
                  contentType(response)?.components(separatedBy: ";")[0]
                    .trimmingCharacters(in: .whitespaces).lowercased() == "application/vnd.bridgee.deferred+json",
                  let data = data else { completion(nil); return }
            completion(decode(data, source: blinklink, origins: appLinkOrigins))
        }.resume()
    }
}

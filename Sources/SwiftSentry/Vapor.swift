import Vapor

extension Request {
    public var sentryContext: RequestContext {
        RequestContext(
            url: url.path,
            method: method.rawValue,
            query_string: url.query,
            headers: sanitizedHeaders,
            data: [
                "http.version": version.description,
            ]
        )
    }

    private var sanitizedHeaders: [String: String] {
        let sensitive: Set<String> = ["authorization", "cookie", "set-cookie", "x-api-key"]
        var result: [String: String] = [:]
        for (name, value) in headers {
            result[name] = sensitive.contains(name.lowercased()) ? "[REDACTED]" : value
        }
        return result
    }
}

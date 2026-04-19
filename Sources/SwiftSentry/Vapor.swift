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

extension Sentry {
    public func capture(
        message: String,
        level: Level?,
        request: Request,
        environment: Vapor.Environment,
        logger: String,
        exceptions: Exceptions?,
        tags: [String: String]?,
        user: User?
    ) -> EventLoopFuture<UUID> {
        let event = Event(
            event_id: UUID(),
            timestamp: Date().timeIntervalSince1970,
            level: level,
            logger: logger,
            transaction: request.route?.path.reduce(into: "") { $0 += "/\($1.description)" },
            server_name: servername,
            release: release,
            tags: tags,
            environment: environment.name,
            message: Message.raw(message: message),
            exception: exceptions,
            request: request.sentryContext,
            breadcrumbs: nil,
            user: user
        )

        return self.send(event: event)
    }

    @discardableResult
    public func capture(
        message: String,
        level: Level?,
        request: Request,
        environment: Vapor.Environment,
        logger: String,
        exceptions: Exceptions?,
        tags: [String: String]?,
        user: User?,
    ) async throws -> UUID {
        try await capture(
            message: message,
            level: level,
            request: request,
            environment: environment,
            logger: logger,
            exceptions: exceptions,
            tags: tags,
            user: user
        ).get()
    }
}

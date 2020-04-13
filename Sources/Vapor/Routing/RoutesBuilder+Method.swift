/// Determines how an incoming HTTP request's body is collected. 
public enum HTTPBodyStreamStrategy {
    /// The HTTP request's body will be collected into memory before the route handler is
    /// called. The max size will determine how much data can be collected. The default is
    /// `1 << 14`.
    ///
    /// See `collect(maxSize:)` to set a lower max body size.
    public static var collect: HTTPBodyStreamStrategy {
        return .collect(maxSize: 1 << 14)
    }

    /// The HTTP request's body will not be collected first before the route handler is called
    /// and will arrive in zero or more chunks.
    case stream

    /// The HTTP request's body will be collected into memory before the route handler is
    /// called.
    ///
    /// If a `maxSize` is supplied, the request body size in bytes will be limited. Requests
    /// exceeding that size will result in an error.
    case collect(maxSize: Int?)
}

extension RoutesBuilder {
    @discardableResult
    public func get<Response>(
        _ path: PathComponent...,
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.GET, path, use: closure)
    }

    @discardableResult
    public func get<Response>(
        _ path: [PathComponent],
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.GET, path, use: closure)
    }
    
    @discardableResult
    public func post<Response>(
        _ path: PathComponent...,
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.POST, path, use: closure)
    }
    
    @discardableResult
    public func post<Response>(
        _ path: [PathComponent],
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.POST, path, use: closure)
    }
    
    @discardableResult
    public func patch<Response>(
        _ path: PathComponent...,
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.PATCH, path, use: closure)
    }
    
    @discardableResult
    public func patch<Response>(
        _ path: [PathComponent],
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.PATCH, path, use: closure)
    }
    
    @discardableResult
    public func put<Response>(
        _ path: PathComponent...,
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.PUT, path, use: closure)
    }
    
    @discardableResult
    public func put<Response>(
        _ path: [PathComponent],
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.PUT, path, use: closure)
    }
    
    @discardableResult
    public func delete<Response>(
        _ path: PathComponent...,
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.DELETE, path, use: closure)
    }
    
    @discardableResult
    public func delete<Response>(
        _ path: [PathComponent],
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(.DELETE, path, use: closure)
    }
    
    @discardableResult
    public func on<Response>(
        _ method: HTTPMethod,
        _ path: PathComponent...,
        body: HTTPBodyStreamStrategy = .collect,
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        return self.on(method, path, body: body, use: { request in
            return try closure(request)
        })
    }
    
    @discardableResult
    public func on<Response>(
        _ method: HTTPMethod,
        _ path: [PathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        use closure: @escaping (Request) throws -> Response
    ) -> Route
        where Response: ResponseEncodable
    {
        let responder = BasicResponder { request in
            if case .collect(let max) = body, request.body.data == nil {
                return request.body.collect(max: max).flatMapThrowing { _ in
                    return try closure(request)
                }.encodeResponse(for: request)
            } else {
                return try closure(request)
                    .encodeResponse(for: request)
            }
        }
        let route = Route(
            method: method,
            path: path,
            responder: responder,
            requestType: Request.self,
            responseType: Response.self
        )
        self.add(route)
        return route
    }
}

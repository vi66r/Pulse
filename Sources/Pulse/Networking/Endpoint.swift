import Foundation

/// An extremely straightforward container for a base URL designed to be used to scope `Endpoint`s.
///
/// Setup:
/// ```
/// extension API {
///     struct Wunderground {
///         static let wunderground = API("https://weatherunderground.com")
///
///         static func weather(for location: String) -> Endpoint {
///             Endpoint(wunderground, "api/weather/\(location)")
///         }
///
///         static func tenDayForecast(for location: String) -> Endpoint {
///             Endpoint(wunderground, "api/10day/\(location)")
///         }
///     }
/// }
/// ```
///
/// Useage:
/// ```
/// class MyClass {
///     init() {
///         let scopedWeatherRequest = API.Wunderground.weather(for: "new_york").request()
///         let tenDayEndpoint = API.Wunderground.tenDayForecast(for: "new_york")
///     }
/// }
/// ```
public struct API: RawRepresentable, Equatable {
    
    public enum AuthenticationStyle {
        case parameter
        case header
        case bearer
    }
    
    public var rawValue: String
    public var baseURL: URL? { URL(string: rawValue) }
    public var authenticationKeyName: String = "key"
    public var authenticationKeyValue: String = ""
    public var authenticationStyle: AuthenticationStyle = .parameter
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    func authenticate(_ request: URLRequest) -> URLRequest {
        guard !authenticationKeyValue.isEmpty else {
            print("⚠️ Authentication attempted against \(rawValue) without valid authorization.",
                  "Please check that you've assigned a value to to \"authenticationKeyValue\"")
            return request
        }
        
        var request = request
        switch authenticationStyle {
        case .parameter:
            if let url = request.url, url.absoluteString.contains("?") {
                request.url = URL(string: url.absoluteString + "&\(authenticationKeyName)=\(authenticationKeyValue)")
            } else if let url = request.url {
                request.url = URL(string: url.absoluteString + "?\(authenticationKeyName)=\(authenticationKeyValue)")
            }
        case .header:
            request.addValue(authenticationKeyValue, forHTTPHeaderField: authenticationKeyName)
        case .bearer:
            request.addValue("Bearer \(authenticationKeyValue)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}

/// `Endpoint` is fundamentally designed to be used as a typed extensible `Enum`, while bypassing the traditional extesibility limitations of enumerations.
/// It requires an `API` value at initialization, to provide a base URL, and is meant to represent the various paths of said web API, however can also be used
/// in conjunction with `API` to scope down to different endpoints. For instance, if you are building a social app, you might scope user profile endpoints to an
/// `API` defined as the base URL representing all calls to `"https://myapp.com/profiles"`.
///
/// `Endpoint` inherently provides convenience builders for both a `URL` and a `URLRequest`, accessible via  the property `url` and the method
/// `request(limit:Int?, offset: Int?)` respectively. The latter has default values of `nil`, and will automatically attach pagination values
/// named `limit` and `offset` if and only if _both_ values are provided. For further discussion on how to use this, see `Paginator`.
///
/// _Caveat Emptor:_ If you try to initialize an endpoint by using the `RawRepresentable` default initializer `init(rawValue: String)`, this will crash.
/// Unfortunately, the method cannot be marked unavailable due to protocol requirements.
///
/// Setup:
/// ```
/// extension Endpoint {
///     static let wunderground = API("https://weatherunderground.com")
///
///     static func weather(for location: String) -> Endpoint {
///         Endpoint(wunderground, "api/weather/\(location)")
///     }
/// }
/// ```
///
/// Useage:
/// ```
/// class MyClass {
///     init() {
///         let weather: Endpoint = .weather(for: "san_francisco")
///         let weatherRequest: URLRequest = Endpoint.weather(for: "san_francisco").request()
///     }
/// }
/// ```
///
/// To see an example of best practice with scoping your endpoints, see `API`.
public struct Endpoint: RawRepresentable, Equatable {
    public var rawValue: String
    public var api: API
    
    public var attachment: Data?
    public var headers: [String : String] = [:]
    public var method: URLRequest.Method
    public var timeout: TimeInterval = 30
    public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    public var contentType: ContentType = .formUrlencoded
    
    public init(_ base: API,
                _ rawValue: String,
                method: URLRequest.Method = .get,
                headers: [String : String] = [:],
                timeout: TimeInterval = 30,
                cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                attachment: Data? = nil
    ) {
        self.api = base
        self.rawValue = rawValue
        self.method = method
        self.headers = headers
        self.timeout = timeout
        self.cachePolicy = cachePolicy
        self.attachment = attachment
    }
    
    public init(rawValue: String) {
        assertionFailure("not designed to be used with this api")
        self.api = API("https://api.publicapis.org/entries")
        self.method = .get
        self.rawValue = rawValue
    }
    
    public var url: URL {
        guard let escapedString = rawValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return URL(string: api.rawValue)! }
        let urlString = api.rawValue + escapedString
        return URL(string: urlString)!
    }
    
    public func multipartRequest(body: [String : String?] = [:], uploadItemName: String = "file", mimeType: String = "img/png", filename: String = "file") -> URLRequest {
        var request: URLRequest
        var headers = headers
        headers["Content-Type"] = ContentType.multipartFormData.rawValue
        request = .multipartRequest(url: url,
                                    method: .post,
                                    cachePolicy: cachePolicy,
                                    timeoutInterval: timeout,
                                    headers: headers,
                                    httpBodyDictionary: body,
                                    uploadItem: attachment,
                                    uploadItemName: uploadItemName,
                                    dataMimeType: mimeType,
                                    filename: filename
        )
        request = api.authenticate(request)
        return request
    }
    
    public func request(limit: Int? = nil, offset: Int? = nil) -> URLRequest {
        var request: URLRequest
        let targetURL: URL
        if let limit = limit, let offset = offset {
            var urlString = url.absoluteString
            urlString = urlString + "?limit=\(limit)&offset=\(offset)"
            targetURL = URL(string: urlString)!
        } else {
            targetURL = url
        }
        
        var headers = headers
        headers["Content-Type"] = contentType.rawValue

        switch self {
        default:
            request = .authenticatedRequest(url: targetURL,
                                            cachePolicy: cachePolicy,
                                            timeoutInterval: timeout,
                                            method: method,
                                            headers: headers,
                                            httpBody: attachment)
        }
        request = api.authenticate(request)
        return request
    }
    
    public mutating func attaching(_ data: Data) -> Endpoint {
        attachment = data
        return self
    }
    
    public mutating func using(_ method: URLRequest.Method) -> Endpoint {
        self.method = method
        return self
    }
    
    public mutating func with(_ headers: [String : String]) -> Endpoint {
        self.headers = headers
        return self
    }
    
    public mutating func with(_ timeout: TimeInterval) -> Endpoint {
        self.timeout = timeout
        return self
    }
    
    public mutating func with(_ cachePolicy: URLRequest.CachePolicy) -> Endpoint {
        self.cachePolicy = cachePolicy
        return self
    }
    
    public mutating func setting(contentType: ContentType) -> Endpoint {
        self.contentType = contentType
        return self
    }
    
    public mutating func addingQueryItems(_ queryItems: [URLQueryItem]) -> Endpoint {
        guard let urlComponents = URLComponents(string: rawValue) else { return self }
        var newComponents = urlComponents
        newComponents.queryItems = (newComponents.queryItems ?? []) + queryItems
        if let urlString = newComponents.url?.absoluteString {
            self.rawValue = urlString
        }
        return self
    }
    
    public func run<T: Decodable>() async throws -> T {
        return try await Networker.execute(self)
    }
}

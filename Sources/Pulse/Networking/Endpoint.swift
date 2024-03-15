import Foundation

/// `API` is a Swift struct designed as a simple yet powerful container for API base URLs, facilitating the scoping and management of network `Endpoint`s.
/// It provides a foundational element for organizing network requests by logically grouping endpoints under specific base URLs, enhancing modularity and clarity 
/// in network code.
///
/// ### Motivation:
/// The primary purpose of `API` is to serve as a centralized configuration point for defining the base URL of a web API. It supports different authentication 
/// strategies, including URL parameters, headers, bearer tokens, or no authentication. This flexibility allows `API` instances to be reused across different parts of
/// an application, promoting consistency and reducing redundancy in network request configurations.
///
/// `API` is designed to work seamlessly with `Endpoint`, allowing for the easy definition and usage of network endpoints that are logically grouped by their base 
/// URL. This design pattern supports a clear and organized structure for API interactions, making the codebase easier to maintain and extend.
///
/// ### Authentication:
/// - `authenticationKeyName`: The name of the key used for authentication (e.g., an API key name or a bearer token prefix).
/// - `authenticationKeyValue`: The value associated with the authentication key (e.g., the actual API key or bearer token value).
/// - `authenticationStyle`: Defines how the authentication information is applied to requests, with options for URL parameter, header, bearer, or no 
/// authentication.
///
/// ### Setup Example:
/// ```swift
/// extension API {
///     struct Wunderground {
///         static let base = API("https://weatherunderground.com")
///         static let testing = API("https://test.weatherunderground.com")
///
///         static func weather(for location: String) -> Endpoint {
///             Endpoint(base, "/api/weather/\(location)")
///         }
///
///         static func tenDayForecast(for location: String) -> Endpoint {
///             Endpoint(base, "/api/10day/\(location)")
///         }
///     }
/// }
/// ```
///
/// ### Usage Example:
/// Demonstrates executing network requests using `Endpoint`, directly and through `Networker`. These examples show how to fetch weather information by 
/// decoding the JSON response into a `WeatherResponse` model.
///
/// #### Using `Networker`:
/// Leverage `Networker` to execute an endpoint and automatically decode the response. This method is preferred for its simplicity and automatic error handling.
/// ```swift
/// func getWeather() async throws -> WeatherResponse {
///     try await Networker.execute(.getWeather(for: "new york"))
/// }
/// ```
///
/// #### Directly from `Endpoint`:
/// Execute the request directly from an `Endpoint` instance with its `run` method, which also supports automatic decoding of the response.
/// ```swift
/// func getWeather() async throws -> WeatherResponse {
///     try await Endpoint.getWeather(for: "new york").run()
/// }
/// ```
///
///
/// By leveraging `API` in conjunction with `Endpoint`, developers can create a more structured, maintainable, and scalable network layer within their Swift 
/// applications. This approach simplifies the management of base URLs and authentication strategies, making it easier to adapt to changes in the API or the
/// application's requirements.
///
/// For a demonstration of defining and using `Endpoint`s within the `API` structure, see the `Endpoint` documentation.

public struct API: RawRepresentable, Equatable {
    
    public enum AuthenticationStyle {
        case parameter
        case header
        case bearer
        case none
    }
    
    public var rawValue: String
    public var baseURL: URL? { URL(string: rawValue) }
    public var authenticationKeyName: String = "key"
    public var authenticationKeyValue: String = ""
    public var authenticationStyle: AuthenticationStyle = .none
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    func authenticate(_ request: URLRequest) -> URLRequest {
        guard authenticationStyle != .none else { return request }
        guard !authenticationKeyValue.isEmpty else {
            print("🌐 PULSE: ⚠️ Authentication attempted against \(rawValue) without valid authorization.",
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
        default:
            break
        }
        
        return request
    }
}

/// `Endpoint` is a Swift struct designed to encapsulate all the necessary details for constructing and executing network requests, including URL construction,
/// HTTP method specification, headers, and optional data attachments. It leverages Swift's type safety and extensibility to streamline API interactions and facilitate
/// the creation of organized, reusable network code.
///
/// ### Motivation:
/// `Endpoint` is fundamentally designed to be used as a typed extensible `Enum`, bypassing the traditional extensibility limitations of enumerations.
/// It requires an `API` value at initialization to provide a base URL and is intended to represent the various paths of said web API. It can also be used
/// in conjunction with `API` to scope down to different endpoints. For instance, for a social app, you might scope user profile endpoints to an
/// `API` defined as the base URL for all calls to `"https://myapp.com/profiles"`.
///
/// `Endpoint` inherently provides convenience builders for both a `URL` and a `URLRequest`, accessible via the property `url` and the method
/// `request(limit: Int?, offset: Int?)` respectively. The latter has default values of `nil` for both parameters and will automatically attach pagination values
/// named `limit` and `offset` if _both_ values are provided, facilitating integration with pagination systems like `Paginator`.
///
/// _Caveat Emptor:_ Initializing an `Endpoint` using the `RawRepresentable` default initializer `init(rawValue: String)` will crash.
/// Unfortunately, the method cannot be marked unavailable due to protocol requirements.
///
/// ### Defaults:
/// - `method`: Defaults to `.get` if not specified. Other HTTP methods can be specified as needed.
/// - `headers`: Initializes empty, allowing you to specify any required HTTP header fields for your request.
/// - `timeout`: Defaults to 30 seconds. This value can be adjusted to fit the needs of specific network requests.
/// - `cachePolicy`: Uses the `.useProtocolCachePolicy` by default, but can be customized to suit different caching strategies.
/// - `contentType`: Defaults to `.json`. It can be set to other content types like `.formUrlencoded` or custom MIME types as necessary.
///
/// ### Setup Example:
/// ```swift
/// extension Endpoint {
///     static let wunderground = API("https://weatherunderground.com")
///
///     static func weather(for location: String) -> Endpoint {
///         Endpoint(wunderground, "/api/weather/\(location)")
///     }
/// }
/// ```
///
/// ### Usage Example:
/// Demonstrates executing network requests using `Endpoint`, directly and through `Networker`. These examples show how to fetch weather information by 
/// decoding the JSON response into a `WeatherResponse` model.
///
/// #### Using `Networker`:
/// Leverage `Networker` to execute an endpoint and automatically decode the response. This method is preferred for its simplicity and automatic error handling.
/// ```swift
/// func getWeather() async throws -> WeatherResponse {
///     try await Networker.execute(.getWeather(for: "new york"))
/// }
/// ```
///
/// #### Directly from `Endpoint`:
/// Execute the request directly from an `Endpoint` instance with its `run` method, which also supports automatic decoding of the response.
/// ```swift
/// func getWeather() async throws -> WeatherResponse {
///     try await Endpoint.getWeather(for: "new york").run()
/// }
/// ```
///
///
/// Additional functionalities such as multipart/form-data requests, custom headers, and other HTTP methods are supported and can be configured
/// through various methods provided by `Endpoint`, enhancing its versatility for different network operation needs.
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
    public var contentType: ContentType = .json
    
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
//        headers["Content-Type"] = ContentType.formUrlencoded.rawValue
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

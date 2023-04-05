import Foundation

public enum NetworkError: Error {
    case badEncode
    case noDataOrBadResponse
    case badDecode
    case customPreconditionFailure
    case noUser
    case backendError(underlying: BackendError)
    case unexpectedResponse(response: String)
}

public struct BackendError: Decodable {
    let error: String
    
    var isRecordNotFound: Bool {
        error == "record not found"
    }
}

public enum DateError: String, Error {
    case invalidDate
}

public class NetworkErrorVerbose: NSError {
    init(request: URLRequest, underlyingError: Error, responseDataAsString: String = "") {
        let targetURL = request.url?.absoluteString ?? ""
        let targetHeaders = request.allHTTPHeaderFields
        let targetMethod = request.httpMethod ?? ""
        
        super.init(domain: "Core Networking Error", code: 3, userInfo: [
            "url": targetURL,
            "headers": targetHeaders ?? [],
            "method": targetMethod,
            "underlyingError": underlyingError,
            "responseDataAsString": responseDataAsString
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("absolutely not")
    }
}

public struct Networker {
    
    public static var debugPrintingEnabled = false
    
    public static func execute(_ endpoint: Endpoint, customPredicate: (() -> Bool)? = nil) async throws {
        try await Networker.execute(request: endpoint.request(), customPredicate: customPredicate)
    }
    
    public static func execute<T: Decodable>(_ endpoint: Endpoint, customPredicate: ((T) -> Bool)? = nil) async throws -> T {
        return try await Networker.execute(request: endpoint.request(), customPredicate: customPredicate)
    }
    
    public static func execute<T: Decodable>(request: URLRequest, customPredicate: ((T) -> Bool)? = nil) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            
            // check to see if the request is in the LRU cache and return early
            
            URLSession.shared.dataTask(
                with: request
            ) { data, response, error in
                
                if debugPrintingEnabled {
                    print(data?.debugPrintAsJSON ?? "There was no data returned.")
                }
                
                if let error = error {
                    Networker.log(error: error, category: "")
                    print(error)
                    continuation.resume(throwing: error)
                    return
                } // log the error
                guard let _ = response, let data = data
                else {
                    Networker.log(
                        error: NetworkErrorVerbose(request: request, underlyingError: NetworkError.noDataOrBadResponse),
                        category: "")
                    continuation.resume(throwing: NetworkError.noDataOrBadResponse)
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(T.self, from: data)
                    guard let customPredicate = customPredicate else {
                        continuation.resume(returning: result)
                        return
                    }
                    guard customPredicate(result) else {
                        let error = NetworkErrorVerbose(request: request, underlyingError: NetworkError.customPreconditionFailure)
                        Networker.log(error: error, category: "")
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: result)
                } catch let error {
                    print(error)
                    let coreNetworkingError = NetworkErrorVerbose(
                        request: request,
                        underlyingError: error,
                        responseDataAsString: data.debugPrintAsJSON
                    )
                    
                    Networker.log(error: coreNetworkingError, category: "")
                    
                    if let errorData = try? JSONDecoder().decode(BackendError.self, from: data) {
                        continuation.resume(throwing: NetworkError.backendError(underlying: errorData))
                        return
                    }
                    
                    continuation.resume(throwing: coreNetworkingError)
                }
                
            }.resume()
        }
    }
    
    public static func execute(request: URLRequest, customPredicate: (() -> Bool)? = nil) async throws {
        return try await withCheckedThrowingContinuation{ continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                if debugPrintingEnabled {
                    print(data?.debugPrintAsJSON ?? "There was no data returned.")
                }
                if let error = error {
                    print(error)
                    continuation.resume(throwing: error)
                    return
                } // log the error
                guard let _ = response, let _ = data
                else {
                    let error = NetworkErrorVerbose(request: request, underlyingError: NetworkError.noDataOrBadResponse)
                    Networker.log(error: error, category: "")
                    continuation.resume(throwing: error)
                    return
                    
                }
                if let customPredicate = customPredicate {
                    if customPredicate() {
                        continuation.resume()
                    } else {
                        let error = NetworkErrorVerbose(request: request, underlyingError: NetworkError.customPreconditionFailure)
                        Networker.log(error: error, category: "")
                        continuation.resume(throwing: error)
                    }
                }
                if let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) {
                    continuation.resume()
                } else {
                    let error = NetworkErrorVerbose(request: request, underlyingError: NetworkError.noDataOrBadResponse)
                    Networker.log(error: error, category: "")
                    continuation.resume(throwing: error)
                }
            }.resume()
        }
    }
    
    public static func stream<T: Decodable>(from endpoint: Endpoint) -> AsyncStream<Result<T, Error>> {
        return stream(from: endpoint.request())
    }

    public static func stream<T: Decodable>(from request: URLRequest, customPredicate: ((T) -> Bool)? = nil) -> AsyncStream<Result<T, Error>> {
        
        return AsyncStream<Result<T, Error>> { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.yield(.failure(error))
                    continuation.finish()
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let data = data else {
                    continuation.yield(.failure(NetworkError.noDataOrBadResponse))
                    continuation.finish()
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(T.self, from: data)
                    guard let customPredicate = customPredicate else {
                        continuation.yield(.success(result))
                        return
                    }
                    guard customPredicate(result) else {
                        let error = NetworkErrorVerbose(request: request, underlyingError: NetworkError.customPreconditionFailure)
                        Networker.log(error: error, category: "")
                        continuation.yield(.failure(error))
                        continuation.finish()
                        return
                    }
                    continuation.yield(.success(result))
                } catch let error {
                    print(error)
                    let coreNetworkingError = NetworkErrorVerbose(
                        request: request,
                        underlyingError: error,
                        responseDataAsString: data.debugPrintAsJSON
                    )
                    
                    Networker.log(error: coreNetworkingError, category: "")
                    continuation.yield(.failure(error))
                    continuation.finish()
                }
            }
            task.resume()
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

public extension Networker {
    static func log(error: Error, category: String) {
        
    }
}

public extension URLRequest {
    enum Method: String {
        case get, post, put, delete, patch, head
        
        var value: String {
            switch self {
            case .get:
                return "GET"
            case .post:
                return "POST"
            case .put:
                return "PUT"
            case .delete:
                return "DELETE"
            case .patch:
                return "PATCH"
            case .head:
                return "HEAD"
            }
        }
    }
    
    static func authenticatedRequest(
        url: URL,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        timeoutInterval: TimeInterval = 30.0,
        method: Method = .get,
        headers: [String : String] = [:],
        httpBody: Data? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        
        request.httpMethod = method.value
        request.allHTTPHeaderFields = headers
        request.httpBody = httpBody
        request.authenticate()
        return request
    }
    
    static func authenticatedMultipartRequest(
        url: URL,
        method: Method = .patch,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        timeoutInterval: TimeInterval = 30.0,
        headers: [String : String] = [:],
        httpBodyDictionary: [String : String?] = [:],
        uploadItem: Data?,
        uploadItemName: String?,
        dataMimeType: String,
        filename: String
    ) -> URLRequest {
        var request = URLRequest.multipartRequest(
            url: url,
            method: method,
            cachePolicy: cachePolicy,
            timeoutInterval: timeoutInterval,
            headers: headers,
            httpBodyDictionary: httpBodyDictionary,
            uploadItem: uploadItem,
            uploadItemName: uploadItemName,
            dataMimeType: dataMimeType,
            filename: filename
        )
        request.authenticate()
        return request
    }
    
    static func multipartRequest(
        url: URL,
        method: Method = .patch,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        timeoutInterval: TimeInterval = 30.0,
        headers: [String : String] = [:],
        httpBodyDictionary: [String : String?] = [:],
        uploadItem: Data?,
        uploadItemName: String?,
        dataMimeType: String,
        filename: String
    ) -> URLRequest {
        let multipartRequest = MultipartRequest(url: url, mimeType: dataMimeType)
        httpBodyDictionary.enumerated().forEach {
            if let value = $0.element.value {
                multipartRequest.addTextField(named: $0.element.key, value: value)
            }
        }
        if let uploadItem = uploadItem, let uploadItemName = uploadItemName {
            multipartRequest.addDataField(named: uploadItemName,
                                          data: uploadItem,
                                          mimeType: dataMimeType,
                                          filename: filename)
        }
        
        var request = multipartRequest.asURLRequest()
        request.httpMethod = method.value
        request.allHTTPHeaderFields = headers
        return request
    }
    
    mutating func authenticate() {
        // do something to add authentication
    }
}

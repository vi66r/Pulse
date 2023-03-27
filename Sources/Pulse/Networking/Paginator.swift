import Combine
import Foundation

public class Paginator<T: Decodable> {
    
    public enum PaginatorError: Error {
        case allLoaded
    }
    
    public var loading = CurrentValueSubject<Bool, Never>(false)
    public var allLoaded: Bool = false
    
    private var limit: Int
    private var offset: Int = 0
    
    public var endpoint: Endpoint
    
    public init(endpoint: Endpoint, limit: Int = 20) {
        self.limit = limit
        self.endpoint = endpoint
    }
    
    public func load(fresh: Bool = false) async throws -> [T] {
        if fresh { offset = 0; allLoaded = false }
        guard !allLoaded, !loading.value else { throw PaginatorError.allLoaded }
        loading.value = true
        let results: [T] = try await Networker.execute(request: endpoint.request(limit: limit, offset: offset))
        loading.value = false
        if results.count < limit { allLoaded = true }
        offset += results.count
        return results
    }
}

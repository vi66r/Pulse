import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol StreamParser {
    associatedtype ResultType: Codable
    func parse(data: Data) throws -> [ResultType]
    func isStreamComplete(data: Data) -> Bool
}

public final class StreamingSession<ResultType: Codable, Parser: StreamParser>: NSObject, URLSessionDataDelegate where Parser.ResultType == ResultType {
    enum StreamingError: Error {
        case unknownContent
        case emptyContent
        case incompleteData
    }

    var onReceiveContent: ((ResultType) -> Void)?
    var onProcessingError: ((Error) -> Void)?
    var onComplete: ((Error?) -> Void)?
    
    private let urlRequest: URLRequest
    private let parser: Parser
    private lazy var urlSession: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var previousChunkBuffer = ""

    public init(urlRequest: URLRequest, parser: Parser) {
        self.urlRequest = urlRequest
        self.parser = parser
    }

    public func perform() {
        urlSession.dataTask(with: urlRequest).resume()
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        onComplete?(error)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let stringContent = String(data: data, encoding: .utf8) else {
            onProcessingError?(StreamingError.unknownContent)
            return
        }
        processJSON(from: stringContent)
    }

    private func processJSON(from stringContent: String) {
        if stringContent.isEmpty {
            onProcessingError?(StreamingError.emptyContent)
            return
        }
        
        let fullContent = previousChunkBuffer + stringContent
        do {
            let objects = try parser.parse(data: Data(fullContent.utf8))
            objects.forEach { onReceiveContent?($0) }
            
            if parser.isStreamComplete(data: Data(fullContent.utf8)) {
                onComplete?(nil)
            } else {
                previousChunkBuffer = fullContent
            }
        } catch {
            onProcessingError?(error)
        }
    }
}


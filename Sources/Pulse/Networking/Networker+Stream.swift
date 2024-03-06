import Combine
import Foundation

extension Networker {

    /// Streams data from a specified `Endpoint` using a `StreamParser` to parse the received data into model objects.
    ///
    /// This method initiates a streaming network request to the specified endpoint. It continuously receives data from the server, parses the data into model 
    /// objects using the provided `StreamParser`, and yields these objects asynchronously through an `AsyncStream`. The stream yields results wrapped
    /// in a `Result` type, allowing for both successful outcomes and errors to be handled.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` specifying the URL and configuration for the streaming network request.
    ///   - parser: A `StreamParser` instance used to parse the received data into model objects.
    /// - Returns: An `AsyncStream` yielding `Result` objects containing either a successfully parsed model or an error.
    ///
    /// ### Example usage:
    /// ```swift
    /// let endpoint = Endpoint(api: someAPI, "/stream")
    /// let parser = MessageStreamParser()
    /// let stream = Networker.stream(from: endpoint, using: parser)
    ///
    /// Task {
    ///     for await result in stream {
    ///         switch result {
    ///         case .success(let message):
    ///             // Handle successful message parsing
    ///         case .failure(let error):
    ///             // Handle parsing or network error
    ///         }
    ///     }
    ///     // at this point (after the for loop), the stream is complete.
    /// }
    /// ```
    ///
    /// This method abstracts the complexities of streaming data handling, parsing, and error management, providing a simple and effective way to consume 
    /// streamed data from network services.
    public static func stream<T: Codable, P: StreamParser>(from endpoint: Endpoint, using parser: P) ->
    AsyncStream<Result<T, Error>> where P.ResultType == T {
        AsyncStream<Result<T, Error>> { continuation in
            let urlRequest = endpoint.request()
            let session = StreamingSession<T, P>(urlRequest: urlRequest, parser: parser)
            session.onReceiveContent = { object in
                continuation.yield(.success(object))
            }
            session.onProcessingError = { error in
                continuation.yield(.failure(error))
            }
            session.onComplete = { error in
                if let error = error {
                    continuation.yield(.failure(error))
                }
                continuation.finish()
            }
            session.perform()
        }
    }

}

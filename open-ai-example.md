# Open AI Use Case

### Last updated: 3/6/24 - not entirely accurate right now ⚠️

### 3/27/23
Since the activities of OpenAI are poppin' right now, here's an example of how you'd link to the completions API.

## Basic Example:

### Setting up the API with bearer authentication:
```swift
extension API {
        static var openAI: API {
            var api = API("https://api.openai.com")
            api.authenticationStyle = .bearer
            api.authenticationKeyValue = "your api key"
            return api
        }
}
```

### Creating an endpoint for chat:

```swift
extension Endpoint {
    static func chatCompletions(api: API, requestModel: OpenAIChatRequest) -> Endpoint {
        let path = "/v1/chat/completions"
        let data = try! JSONEncoder().encode(requestModel)
        
        var endpoint = Endpoint(api, path, method: .post, attachment: data)
        endpoint = endpoint.setting(contentType: .json)
        return endpoint
    }
}
```

### Running Your Streaming Request

Implement a parser conforming to `StreamParser` to interpret the streamed data chunks.

#### Example StreamParser for OpenAI Completion Responses

```swift
struct OpenAIStreamParser: StreamParser {
    func parse(data: Data) throws -> [OpenAICompletionResponse] {
        // Parsing logic to handle streamed JSON data
        let decoder = JSONDecoder()
        let response = try decoder.decode([OpenAICompletionResponse].self, from: data)
        return response
    }
    
    func isStreamComplete(data: Data) -> Bool {
        // Logic to determine if the streaming is complete
        return false
    }
}
```

#### Executing the Streaming Request

```swift
func getChatCompletionsStreaming(requestModel: OpenAIChatRequest) async {
    let endpoint = Endpoint.chatCompletions(api: .openAI, requestModel: requestModel)
    let parser = OpenAIChatResponseParser() // Assuming you've implemented this parser

    let stream = Networker.stream(from: endpoint, using: parser)

    for await result in stream {
        switch result {
        case .success(let chatResponse):
            print("Received chat response: \(chatResponse)")
        case .failure(let error):
            print("Error: \(error.localizedDescription)")
        }
    }
}
```

### Running your Completions request:
Where `OpenAICompletionResponse` is a `Codable` matching the shape of your data, assuming you've set up a compoetions endpoint:
```swift
func getCompletions() async throws -> OpenAICompletionResponse {
    try await Networker.execute(.completions(for: "A long time ago in a galaxy far, far away...."))
}
```
Alternatively:
```swift
func getCompletions() async throws -> OpenAICompletionResponse { 
    try await Endpoint.completions(for: "A long time ago in a galaxy far, far away....").run()
}
```

### Curious about what `OpenAICompletionResponse` looks like?
```swift
struct OpenAICompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let usage: Usage
    let choices: [Choice]
}

struct Usage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

struct Choice: Codable {
    let text: String
    let index: Int
    let logprobs: Logprobs?
    let finish_reason: String
}

struct Logprobs: Codable {
    let tokens: [String]
    let token_logprobs: [Double]
    let top_logprobs: [[String: Double]]
    let text_offset: [Int]
}
```
lol

Made with ❤️ on Long Island.

<img src="https://img.icons8.com/tiny-color/512/twitter.png"  width="12" height="12"> [Connect?](https://twitter.com/definitelyrafi)


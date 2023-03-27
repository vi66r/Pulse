# Open AI Use Case

3/27/23
Since the activities of OpenAI are poppin' right now, here's an example of how you'd link to the completions API.

## Basic Example:

### Setting up the API with parameter authentication:
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

### Creating an endpoint for completions:

```swift
extension Endpoint {
    static func completions(for prompt: String, maxTokens: Int = 500, temperature: Float = 0.5, topP: Float = 1.0) -> Endpoint {
        let path = "/v1/engines/davinci-codex/completions?"
        let queryItems = [
            URLQueryItem(name: "prompt", value: prompt),
            URLQueryItem(name: "max_tokens", value: "\(maxTokens)"),
            URLQueryItem(name: "temperature", value: "\(temperature)"),
            URLQueryItem(name: "top_p", value: "\(topP)")
        ]
        var endpoint = Endpoint(.openAI, path, method: .post)
        return endpoint.addingQueryItems(queryItems)
    }
}
```

### Running your request:
Where `OpenAICompletionResponse` is a `Codable` matching the shape of your data:
```swift
func getCompletions() async throws -> OpenAICompletionResponse {
    try await Networker.execute(.completions(for: "Long long ago, in a galaxy, far far away"))
}
```
Alternatively:
```swift
func getCompletions() async throws -> OpenAICompletionResponse { 
    try await Endpoint.completions(for: "Long long ago, in a galaxy, far far away").run()
}
```

### Curious about what `OpenAICompletionResponse` looks like?
```swift
public struct OpenAICompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let usage: Usage
    let choices: [Choice]
}

public struct Usage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

public struct Choice: Codable {
    let text: String
    let index: Int
    let logprobs: Logprobs?
    let finish_reason: String
}

public struct Logprobs: Codable {
    let tokens: [String]
    let token_logprobs: [Double]
    let top_logprobs: [[String: Double]]
    let text_offset: [Int]
}
```
lol

Made with ❤️ from NY.

<img src="https://img.icons8.com/tiny-color/512/twitter.png"  width="12" height="12"> [Connect?](https://twitter.com/definitelyrafi)


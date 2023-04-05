# Open AI Use Case

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

### Creating an endpoint for completions:

```swift
extension Endpoint {
    static func completions(api: API, prompt: String, maxTokens: Int, temperature: Double, topP: Double) -> Endpoint {
        let path = "/v1/completions?"
        
        let attachment = OpenAICompletionRequest(
            model: "text-davinci-003",
            prompt: prompt,
            max_tokens: maxTokens,
            temperature: temperature,
            top_p: topP
        )

        let data = try! JSONEncoder().encode(attachment)
        
        var endpoint = Endpoint(api, path, method: .post, timeout: 300, attachment: data)
        endpoint = endpoint.setting(contentType: .json)
        return endpoint
    }
}
```

### Running your request:
Where `OpenAICompletionResponse` is a `Codable` matching the shape of your data:
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


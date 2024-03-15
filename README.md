
# Pulse

A nifty little networking library designed for the _swift <img src="https://cdn-icons-png.flaticon.com/512/5968/5968371.png" width="12" height="12">_ development of APIs and the execution of network requests with minimal setup. Perfect for when you want to get things up and running without the fuss.

_fun fact: this library was named by GPT-3.5-turbo_

## What's New:

**Streaming Support**: Pulse now handles streaming data

## Basic Example:

### Setting up an API with Parameter Authentication:
```swift
extension API {
    static var weather: API {
        var api = API("https://api.weatherapi.com/v1/current.json")
        api.authenticationKeyName = "key"
        api.authenticationStyle = .parameter // also supports .bearer, .header, and .none
        api.authenticationKeyValue = "your weather api key"
        return api
    }
}
```

### Creating an Endpoint for Weather:
```swift
extension Endpoint {
    static func getWeather(for location: String) -> Endpoint { 
        Endpoint(.weather, "?q=\(location)")
    }
}
```
For static endpoints without dynamic parameters, `static vars` are your best friend.

### Running Your Weather Request:
Where `WeatherResponse` is a `Codable` matching the shape of your data:
```swift
func getWeather() async throws -> WeatherResponse { 
    try await Networker.execute(.getWeather(for: "new york"))
}
```
Or, for a more direct approach:
```swift
func getWeather() async throws -> WeatherResponse { 
    try await Endpoint.getWeather(for: "new york").run()
}
```

## Streaming Made Simple:

### Setting Up a Text Stream API Endpoint:
Imagine a live blog or news feed that streams updates:
```swift
extension API {
    static var liveTextStream: API {
        API("https://api.livetextstream.com/v1/updates")
    }
}
```

### Creating a Streaming Endpoint for Text Updates:
```swift
extension Endpoint {
    static func liveTextUpdates(eventId: String) -> Endpoint {
        Endpoint(.liveTextStream, "/stream?eventId=\(eventId)", method: .get)
    }
}
```

### Define your codable and a `StreamParser` to consume the stream:

```swift
struct TextUpdate: Codable {
    let content: String
}

class TextUpdateStreamParser: StreamParser {
    typealias ResultType = TextUpdate

    func parse(data: Data) throws -> [TextUpdate] {
        // Assuming each data chunk represents a single TextUpdate in JSON format.
        // This example simply tries to decode a TextUpdate from the provided data.
        // In a real-world scenario, you might need to accumulate data until a complete
        // JSON object can be parsed or implement more complex parsing logic.
        
        let decoder = JSONDecoder()
        if let update = try? decoder.decode(TextUpdate.self, from: data) {
            return [update]
        } else {
            // Handling cases where data might not be a complete JSON object for decoding
            // or implement your logic to accumulate partial data chunks.
            return []
        }
    }

    func isStreamComplete(data: Data) -> Bool {
        // Implement logic to determine if the stream is complete.
        // This could be based on specific markers in the data or external conditions.
        // For simplicity, this example does not implement stream completion detection.
        return false
    }
}
```

* This is liable to get updated so you don't have to do manual decoding...

### Consuming the Text Stream:
Assuming `TextUpdate` is your model for each text chunk:
```swift
func watchLiveText(eventId: String) async {
    let stream = Networker.stream(from: .liveTextUpdates(eventId: eventId), using: TextUpdateStreamParser())

    var completeText = ""
    for await result in stream {
        switch result {
        case .success(let update):
            completeText += update.content
            print("Latest Text: \(completeText)")
        case .failure(let error):
            print("Streaming Error: \(error)")
        }
    }
}
```

[_Wanna see something cool?_](https://github.com/vi66r/Pulse/blob/main/open-ai-example.md)

Made with ❤️ on Long Island.

<img src="https://img.icons8.com/tiny-color/512/twitter.png" width="12" height="12"> [Connect?](https://twitter.com/definitelyrafi)

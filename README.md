# Pulse

A very tiny networking library that allows you to rapidly build APIs, and run network requests with minimal groundwork.

_very random fun fact: this library was named by GPT-3.5-turbo" 

## Basic Example:

### Setting up an API with parameter authentication:
```
extension API {
        static var weather: API {
            var api = API("https://api.weatherapi.com/v1/current.json")
            api.authenticationKeyName = "key"
            api.authenticationStyle = .parameter
            api.authenticationKeyValue = "your weather api key"
            return api
        }
}
```
You can also use `.header` or `.bearer` for the `authenticationStyle`. The latter will automatically set up for a bearer token. This will cover most use cases unless the auth for the API you're trying to connect to requires some other sort of header key. 

### Creating an endpoint for that API:

```
extension Endpoint {
    static func getWeather(for location: String) -> Endpoint { Endpoint(.weather, "?q=\(location)") }
}
```
You can also use `static vars` for this, assuming you don't have an input parameter. 

### Running your request:
Where `WeatherResponse` is a `Codable` matching the shape of your data:
```
func getWeather() async throws -> WeatherResponse { 
    try await Networker.execute(.getWeather(for: "new york"))
}
```
Alternatively:
```
func getWeather() async throws -> WeatherResponse { 
    try await Endpoint.getWeather(for: "new york").run()
}
```


Made with ❤️ from NY.

<img src="https://img.icons8.com/tiny-color/512/twitter.png"  width="12" height="12"> [Connect?](https://twitter.com/definitelyrafi)

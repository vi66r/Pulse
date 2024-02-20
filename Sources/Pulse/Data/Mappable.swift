import Foundation

public protocol Mappable {
    /**
     Maps the properties of the calling `Codable` object into another `Codable` type, assuming matching property names and compatible types.
     
     This method uses reflection to dynamically inspect the properties of the calling object, constructs a dictionary representation, and then attempts to decode an instance of the specified target type from this dictionary. This approach allows for flexible mapping between types without requiring manual coding for each property.
     
     - Parameter type: The target `Codable` type into which the properties should be mapped. This type must have a `Decodable` conformance.
     - Returns: An instance of the target type, populated with the properties from the calling object that match by name and are compatible by type.
     - Throws: `MappableError.serializationError` if the object cannot be serialized into JSON, possibly due to incompatible property types.
     `MappableError.decodingError` if the JSON cannot be decoded into the target type, possibly due to missing keys or type mismatches.
     Other errors may be thrown by the underlying JSON serialization or decoding processes.
     
     ### Usage Example: ###
     ```swift
     struct User: Codable {
         var name: String
         var age: Int
     }
     
     struct Person: Codable {
         var name: String
         var age: Int
         var email: String
     }
     
     let user = User(name: "Jane Doe", age: 28)
     do {
         let person: Person = try user.mapInto(Person.self)
         print(person.name) // "Jane Doe"
         print(person.age)  // 28
     } catch {
        print("Mapping failed with error: \(error.localizedDescription)")
     }
     ```
     */
    func mapInto<T: Codable>(_ type: T.Type) throws -> T
}

enum MappableError: Error {
    case serializationError(String)
    case decodingError(String)
}

extension MappableError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .serializationError(let message):
            return "Serialization error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}


public extension Mappable where Self: Codable {
    func mapInto<T: Codable>(_ type: T.Type) throws -> T {
        let mirror = Mirror(reflecting: self)
        var dictionary = [String: Any]()
        
        for case let (label?, value) in mirror.children {
            dictionary[label] = value
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSPropertyListWriteInvalidError {
            throw MappableError.serializationError("Failed to serialize object to JSON. This may be due to incompatible property types. Original error: \(error.localizedDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            throw MappableError.decodingError("Failed to decode JSON to target type \(T.self). Missing key '\(key.stringValue)' in the JSON. Context: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            throw MappableError.decodingError("Type mismatch in JSON decoding for target type \(T.self). Type '\(type)' did not match the expected type. Context: \(context.debugDescription)")
        } catch {
            throw error
        }
    }
}


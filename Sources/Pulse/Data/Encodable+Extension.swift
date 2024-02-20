import Foundation

public extension Encodable {
    func JSON(prettyPrint: Bool = false) -> String? {
        let encoder = JSONEncoder()
        if prettyPrint {
            encoder.outputFormatting = .prettyPrinted
        }
        
        do {
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error encoding JSON: \(error)")
            return nil
        }
    }
}


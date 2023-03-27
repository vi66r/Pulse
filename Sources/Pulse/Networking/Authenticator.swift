import Combine
import Foundation

public protocol Authenticating {
    var authenticationAvailablePublisher: PassthroughSubject<Bool, Never> { get }
    var bearerToken: String? { get set }
    var refreshToken: String? { get set }
}

public final class Authenticator: Authenticating {
    public let authenticationAvailablePublisher = PassthroughSubject<Bool, Never>()
    public var bearerToken: String? {
        didSet {
            authenticationAvailablePublisher.send(bearerToken != nil)
        }
    }
    public var refreshToken: String?
}

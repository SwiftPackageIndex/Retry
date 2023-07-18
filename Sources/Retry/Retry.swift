import Foundation


enum Retry {
    public enum Error: Swift.Error, Equatable {
        case retryLimitExceeded(lastError: String?)
    }

    public static func backedOffDelay(baseDelay: Double, attempt: Int) -> UInt32 {
        (pow(2, max(0, attempt - 1)) * Decimal(baseDelay) as NSDecimalNumber).uint32Value
    }

    public static func attempt<T>(_ label: String,
                                  delay: Double = 5,
                                  retries: Int = 5,
                                  _ block: () throws -> T) throws -> T {
        var retriesLeft = retries
        var currentTry = 1
        var lastError: String?
        while true {
            if currentTry > 1 {
                print("\(label) (attempt \(currentTry))")
            }
            do {
                return try block()
            } catch {
                lastError = "\(error)"
                guard retriesLeft > 0 else { break }
                let delay = backedOffDelay(baseDelay: delay, attempt: currentTry)
                print("Retrying in \(delay) seconds ...")
                sleep(delay)
                currentTry += 1
                retriesLeft -= 1
            }
        }
        throw Error.retryLimitExceeded(lastError: lastError)
    }
}

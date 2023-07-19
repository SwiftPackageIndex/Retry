// Copyright Dave Verwer, Sven A. Schmidt, and other contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation


public enum Retry {
    public enum Error: Swift.Error, Equatable {
        case retryLimitExceeded(lastError: String?)
    }

    public static func backedOffDelay(baseDelay: Double, attempt: Int) -> UInt32 {
        (pow(2, max(0, attempt - 1)) * Decimal(baseDelay) as NSDecimalNumber).uint32Value
    }

    public static func attempt<T>(_ label: String,
                                  delay: Double = 5,
                                  retries: Int = 5,
                                  logger: RetryLogging = DefaultLogger(),
                                  _ block: () throws -> T) throws -> T {
        var retriesLeft = retries
        var currentTry = 1
        var lastError: String?
        while true {
            if currentTry > 1 {
                logger.onStartOfRetry(label: label, attempt: currentTry)
            }
            do {
                return try block()
            } catch {
                lastError = "\(error)"
                guard retriesLeft > 0 else { break }
                let delay = backedOffDelay(baseDelay: delay, attempt: currentTry)
                logger.onStartOfDelay(label: label, delay: Double(delay))
                sleep(delay)
                currentTry += 1
                retriesLeft -= 1
            }
        }
        throw Error.retryLimitExceeded(lastError: lastError)
    }
}


public protocol RetryLogging {
    func onStartOfRetry(label: String, attempt: Int)
    func onStartOfDelay(label: String, delay: Double)
}


public struct DefaultLogger: RetryLogging {
    public init() { }

    public func onStartOfRetry(label: String, attempt: Int) {
        print("\(label) (attempt \(attempt))")
    }

    public func onStartOfDelay(label: String, delay: Double) {
        print("Retrying in \(delay) seconds ...")
    }
}



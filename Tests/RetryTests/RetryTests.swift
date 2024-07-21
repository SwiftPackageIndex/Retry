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

import XCTest
@testable import Retry

final class RetryTests: XCTestCase {

    func test_backedOffDelay() throws {
        XCTAssertEqual(Retry.backedOffDelay(baseDelay: 1, attempt: 0), 1)
        XCTAssertEqual(Retry.backedOffDelay(baseDelay: 1, attempt: 1), 1)
        XCTAssertEqual(Retry.backedOffDelay(baseDelay: 1, attempt: 2), 2)
        XCTAssertEqual(Retry.backedOffDelay(baseDelay: 1, attempt: 3), 4)
        XCTAssertEqual(Retry.backedOffDelay(baseDelay: 1, attempt: 4), 8)
    }

    func test_attempt_immediate_success() throws {
        var called = 0

        // MUT
        try Retry.attempt("", delay: 0, retries: 3) {
            called += 1
        }

        // validation
        XCTAssertEqual(called, 1)
    }

    func test_attempt_success_after_retry() throws {
        var called = 0
        struct Error: Swift.Error { }

        // MUT
        try Retry.attempt("", delay: 0, retries: 3) {
            called += 1
            if called < 3 {
                throw Error()
            }
        }

        // validation
        XCTAssertEqual(called, 3)
    }

    func test_attempt_retryLimitExceeded() throws {
        var called = 0
        struct Error: Swift.Error, CustomStringConvertible {
            var description: String { "test error" }
        }

        // MUT
        do {
            try Retry.attempt("", delay: 0, retries: 3) {
                called += 1
                throw Error()
            }
            XCTFail("expected an error to be thrown")
        } catch let Retry.Error.retryLimitExceeded(lastError: .some(error)) {
            XCTAssertEqual("\(error)", "test error")
        } catch {
            XCTFail("unexpected error: \(error)")
        }

        // validation
        XCTAssertEqual(called, 4)
    }

    func test_attempt_async() async throws {
        func dummyAsyncFunction() async { }
        var called = 0

        // MUT
        try await Retry.attempt("", delay: 0, retries: 3) {
            await dummyAsyncFunction()
            called += 1
        }

        // validation
        XCTAssertEqual(called, 1)
    }

}

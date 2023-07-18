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
        XCTAssertThrowsError(
            try Retry.attempt("", delay: 0, retries: 3) {
                called += 1
                throw Error()
            }

        ) { error in
            XCTAssertEqual(error as? Retry.Error, .retryLimitExceeded(lastError: "test error"))
        }

        // validation
        XCTAssertEqual(called, 4)
    }

}

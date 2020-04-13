import XCTest
import Vapor

final class ErrorTests: XCTestCase {
    func testPrintable() throws {
        print(FooError.noFoo.debugDescription)

        let expectedPrintable = """
        Foo Error: You do not have a `foo`.
        - id: FooError.noFoo

        Here are some possible causes:
        - You did not set the flongwaffle.
        - The session ended before a `Foo` could be made.
        - The universe conspires against us all.
        - Computers are hard.

        These suggestions could address the issue:
        - You really want to use a `Bar` here.
        - Take up the guitar and move to the beach.

        Vapor's documentation talks about this:
        - http://documentation.com/Foo
        - http://documentation.com/foo/noFoo
        """
        XCTAssertEqual(FooError.noFoo.debugDescription, expectedPrintable)
    }

    func testOmitEmptyFields() {
        XCTAssertTrue(FooError.noFoo.stackOverflowQuestions.isEmpty)
        XCTAssertFalse(
            FooError.noFoo.debugDescription.contains("Stack Overflow")
        )
    }

    func testReadableName() {
        XCTAssertEqual(FooError.readableName, "Foo Error")
    }

    func testIdentifier() {
        XCTAssertEqual(FooError.noFoo.identifier, "noFoo")
    }

    func testCausesAndSuggestions() {
        XCTAssertEqual(FooError.noFoo.possibleCauses, [
            "You did not set the flongwaffle.",
            "The session ended before a `Foo` could be made.",
            "The universe conspires against us all.",
            "Computers are hard."
        ])

        XCTAssertEqual(FooError.noFoo.suggestedFixes, [
            "You really want to use a `Bar` here.",
            "Take up the guitar and move to the beach."
        ])

        XCTAssertEqual(FooError.noFoo.documentationLinks, [
            "http://documentation.com/Foo",
            "http://documentation.com/foo/noFoo"
        ])
    }

    func testMinimumConformance() {
        let minimum = MinimumError.alpha
        let description = minimum.debugDescription
        let expectation = """
        MinimumError: Not enabled
        - id: MinimumError.alpha
        """
        XCTAssertEqual(description, expectation)
    }

    func testErrorLogging() {
        let logger = Logger(label: "codes.vapor.test")
        logger.report(error: FooError.noFoo)
    }

    func testErrorLogging_stacktrace() {
        let logger = Logger(label: "codes.vapor.test")

        func foo() throws {
            try bar()
        }
        func bar() throws {
            try baz()
        }
        func baz() throws {
            throw TestError(kind: .foo, reason: "Oops")
        }

        do {
            try foo()
        } catch {
            logger.report(error: error)
        }
    }

    func testStackTrace() {
        StackTrace.isCaptureEnabled = false
        XCTAssertNil(StackTrace.capture())
        StackTrace.isCaptureEnabled = true
        print(StackTrace.capture()!.description)
    }
}

private enum MinimumError: String, DebuggableError {
    case alpha, bravo, charlie

    /// The reason for the error.
    /// Typical implementations will switch over `self`
    /// and return a friendly `String` describing the error.
    /// - note: It is most convenient that `self` be a `Swift.Error`.
    ///
    /// Here is one way to do this:
    ///
    ///     switch self {
    ///     case someError:
    ///        return "A `String` describing what went wrong including the actual error: `Error.someError`."
    ///     // other cases
    ///     }
    var reason: String {
        switch self {
            case .alpha:
                return "Not enabled"
            case .bravo:
                return "Enabled, but I'm not configured"
            case .charlie:
                return "Broken beyond repair"
        }
    }

    var identifier: String {
        return rawValue
    }

    /// A `String` array describing the possible causes of the error.
    /// - note: Defaults to an empty array.
    /// Provide a custom implementation to give more context.
    var possibleCauses: [String] {
        return []
    }

    var suggestedFixes: [String] {
        return []
    }
}


private enum FooError: String, DebuggableError {
    case noFoo

    static var readableName: String {
        return "Foo Error"
    }

    var identifier: String {
        return rawValue
    }

    var reason: String {
        switch self {
        case .noFoo:
            return "You do not have a `foo`."
        }
    }

    var possibleCauses: [String] {
        switch self {
        case .noFoo:
            return [
                "You did not set the flongwaffle.",
                "The session ended before a `Foo` could be made.",
                "The universe conspires against us all.",
                "Computers are hard."
            ]
        }
    }

    var suggestedFixes: [String] {
        switch self {
        case .noFoo:
            return [
                "You really want to use a `Bar` here.",
                "Take up the guitar and move to the beach."
            ]
        }
    }

    var documentationLinks: [String] {
        switch self {
        case .noFoo:
            return [
                "http://documentation.com/Foo",
                "http://documentation.com/foo/noFoo"
            ]
        }
    }
}

private struct TestError: DebuggableError {
    enum Kind: String {
        case foo
        case bar
        case baz
    }

    var kind: Kind
    var reason: String
    var source: ErrorSource?
    var stackTrace: StackTrace?

    init(
        kind: Kind,
        reason: String,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column,
        stackTrace: StackTrace? = .capture()
    ) {
        self.kind = kind
        self.reason = reason
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
        self.stackTrace = stackTrace
    }

    var identifier: String {
        return kind.rawValue
    }

    var possibleCauses: [String] {
        switch kind {
        case .foo:
            return ["What do you expect, you're testing errors."]
        default:
            return []
        }
    }

    var suggestedFixes: [String] {
        switch kind {
        case .foo:
            return ["Get a better keyboard to chair interface."]
        default:
            return []
        }
    }
}

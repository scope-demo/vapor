extension Logger {
    /// Reports an `Error` to this `Logger`.
    ///
    /// - parameters:
    ///     - error: `Error` to log.
    public func report(
        error: Error,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        let source: ErrorSource?
        let reason: String
        switch error {
        case let debuggable as DebuggableError:
            if self.logLevel <= .debug {
                reason = debuggable.debuggableHelp(format: .short)
            } else {
                reason = debuggable.debuggableHelp(format: .long)
            }
            source = debuggable.source
        case let abort as AbortError:
            reason = abort.reason
            source = nil
        case let localized as LocalizedError:
            reason = localized.localizedDescription
            source = nil
        case let convertible as CustomStringConvertible:
            reason = convertible.description
            source = nil
        default:
            reason = "\(error)"
            source = nil
        }
        self.log(
            level: .error,
            .init(stringLiteral: reason),
            file: source?.file ?? file,
            function: source?.function ?? function,
            line: numericCast(source?.line ?? line)
        )
    }
}

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?
    var stackTrace: StackTrace?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column,
        stackTrace: StackTrace? = .capture()
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
        self.stackTrace = stackTrace
    }
}

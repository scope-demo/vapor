import Foundation

/// `Debuggable` provides an interface that allows a type
/// to be more easily debugged in the case of an error.
public protocol DebuggableError: LocalizedError, CustomDebugStringConvertible, CustomStringConvertible {
    /// A readable name for the error's Type. This is usually
    /// similar to the Type name of the error with spaces added.
    /// This will normally be printed proceeding the error's reason.
    /// - note: For example, an error named `FooError` will have the
    /// `readableName` `"Foo Error"`.
    static var readableName: String { get }

    /// A unique identifier for the error's Type.
    /// - note: This defaults to `ModuleName.TypeName`,
    /// and is used to create the `identifier` property.
    static var typeIdentifier: String { get }

    /// Some unique identifier for this specific error.
    /// This will be used to create the `identifier` property.
    /// Do NOT use `String(reflecting: self)` or `String(describing: self)`
    /// or there will be infinite recursion
    var identifier: String { get }

    /// The reason for the error. Usually one sentence (that should end with a period).
    var reason: String { get }

    /// Optional source for this error
    var source: ErrorSource? { get }

    /// Stack trace from which this error originated (must set this from the error's init)
    var stackTrace: StackTrace? { get }

    /// A `String` array describing the possible causes of the error.
    /// - note: Defaults to an empty array.
    /// Provide a custom implementation to give more context.
    var possibleCauses: [String] { get }

    /// A `String` array listing some common fixes for the error.
    /// - note: Defaults to an empty array.
    /// Provide a custom implementation to be more helpful.
    var suggestedFixes: [String] { get }

    /// An array of string `URL`s linking to documentation pertaining to the error.
    /// - note: Defaults to an empty array.
    /// Provide a custom implementation with relevant links.
    var documentationLinks: [String] { get }

    /// An array of string `URL`s linking to related Stack Overflow questions.
    /// - note: Defaults to an empty array.
    /// Provide a custom implementation to link to useful questions.
    var stackOverflowQuestions: [String] { get }

    /// An array of string `URL`s linking to related issues on Vapor's GitHub repo.
    /// - note: Defaults to an empty array.
    /// Provide a custom implementation to a list of pertinent issues.
    var gitHubIssues: [String] { get }
}

extension DebuggableError {
    public var fullIdentifier: String {
        return Self.typeIdentifier + "." + self.identifier
    }
}

// MARK: Defaults
extension DebuggableError {
    /// See `Debuggable`
    public static var readableName: String {
        self.typeIdentifier
    }

    /// See `Debuggable`
    public static var typeIdentifier: String {
        let type = "\(self)"
        return type.split(separator: ".").last.flatMap(String.init) ?? type
    }

    /// See `Debuggable`
    public var possibleCauses: [String] {
        []
    }

    /// See `Debuggable`
    public var suggestedFixes: [String] {
        []
    }

    /// See `Debuggable`
    public var documentationLinks: [String] {
        []
    }

    /// See `Debuggable`
    public var stackOverflowQuestions: [String] {
        []
    }

    /// See `Debuggable`
    public var gitHubIssues: [String] {
        []
    }

    /// See `Debuggable`
    public var source: ErrorSource? {
        nil
    }

    /// See `Debuggable`
    public var stackTrace: StackTrace? {
        nil
    }
}

/// MARK: Custom...StringConvertible
extension DebuggableError {
    /// See `CustomDebugStringConvertible`
    public var debugDescription: String {
        self.debuggableHelp(format: .long)
    }

    /// See `CustomStringConvertible`
    public var description: String {
        self.debuggableHelp(format: .short)
    }
}

// MARK: Localized
extension DebuggableError {
    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        self.description
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? {
        self.reason
    }

    /// A localized message describing how one might recover from the failure.
    public var recoverySuggestion: String? {
        self.suggestedFixes.first
    }

    /// A localized message providing "help" text if the user requests help.
    public var helpAnchor: String? {
        self.documentationLinks.first
    }
}


// MARK: Representations
/// Available formatting options for generating debug info for `Debuggable` errors.
public enum HelpFormat {
    case short
    case long
}

extension DebuggableError {
    /// A computed property returning a `String` that encapsulates why the error occurred, suggestions on how to
    /// fix the problem, and resources to consult in debugging (if these are available).
    /// - note: This representation is best used with functions like print()
    public func debuggableHelp(format: HelpFormat) -> String {
        var print: [String] = []

        switch format {
        case .long:
            print.append("\(Self.readableName): \(self.reason)\n- id: \(self.fullIdentifier)")
        case .short:
            print.append("\(self.fullIdentifier): \(self.reason)")
        }

        if let source = self.source {
            switch format {
            case .long:
                var help: [String] = []
                help.append("File: \(source.file)")
                help.append("- func: \(source.function)")
                help.append("- line: \(source.line)")
                help.append("- column: \(source.column)")
                if let range = source.range {
                    help.append("- range: \(range)")
                }
                print.append(help.joined(separator: "\n"))
            case .short:
                var string = "[\(source.file):\(source.line):\(source.column)"
                if let range = source.range {
                    string += " (\(range))"
                }
                string += "]"
                print.append(string)
            }
        }

        switch format {
        case .long:
            if !self.possibleCauses.isEmpty {
                print.append("Here are some possible causes:\(self.possibleCauses.bulletedList)")
            }

            if !self.suggestedFixes.isEmpty {
                print.append("These suggestions could address the issue:\(self.suggestedFixes.bulletedList)")
            }

            if !self.documentationLinks.isEmpty {
                print.append("Vapor's documentation talks about this:\(self.documentationLinks.bulletedList)")
            }

            if !self.stackOverflowQuestions.isEmpty {
                print.append("These Stack Overflow links might be helpful:\(self.stackOverflowQuestions.bulletedList)")
            }

            if !self.gitHubIssues.isEmpty {
                print.append("See these Github issues for discussion on this topic:\(self.gitHubIssues.bulletedList)")
            }
            if let stackTrace = self.stackTrace {
                print.append("Stack trace:\n\(stackTrace)")
            }
        case .short:
            if self.possibleCauses.count > 0 {
                print.append("[Possible causes: \(self.possibleCauses.joined(separator: " "))]")
            }
            if self.suggestedFixes.count > 0 {
                print.append("[Suggested fixes: \(self.suggestedFixes.joined(separator: " "))]")
            }
        }

        switch format {
        case .long:
            return print.joined(separator: "\n\n")
        case .short:
            return print.joined(separator: " ")
        }
    }
}


extension Sequence where Iterator.Element == String {
    var bulletedList: String {
        self.map { "\n- \($0)" } .joined()
    }
}

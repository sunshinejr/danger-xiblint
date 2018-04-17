import Danger
import Foundation

// Xiblint needs:
// --path option to lint only a single file on the fly (without a config)
// rule severity? if not, let's just give an option to choose if given error is in fact an error or a warning

public enum XiblintError: Error {
    case serialization(json: String, error: Error)

    var message: String {
        switch self {
        case let .serialization(json, error):
            return "Error deserializing xiblint JSON response (\(json)): \(error)"
        }
    }
}

public struct Xiblint {
    internal static let danger = Danger()
    internal static let shellExecutor = ShellExecutor()

    /// This is the main entry point for linting Swift in PRs using Danger-Swift.
    /// Call this function anywhere from within your Dangerfile.swift.
    @discardableResult
    public static func lint(inline: Bool = false) -> [Violation] {
        // First, for debugging purposes, print the working directory.
        print("Working directory: \(shellExecutor.execute("pwd"))")
        return self.lint(danger: danger, shellExecutor: shellExecutor, inline: inline)
    }
}

/// This extension is for internal workings of the plugin. It is marked as internal for unit testing.
internal extension Xiblint {

    typealias FilePath = String

    static func lint(
        danger: DangerDSL,
        shellExecutor: ShellExecutor,
        inline: Bool = false,
        markdownAction: (String) -> Void = markdown,
        failAction: (String) -> Void = fail,
        failInlineAction: (String, String, Int) -> Void = fail,
        warnInlineAction: (String, String, Int) -> Void = warn) -> [Violation] {

        // Gathers modified+created files, invokes Xiblint on each, and posts collected errors+warnings to Danger.
        // Currently it's not working for the paths, but we're working on it (TM).
        var files = danger.git.createdFiles + danger.git.modifiedFiles
        let xibFiles = files.filter { $0.hasSuffix(".xib") || $0.hasSuffix(".storyboard") }

        do {
            let xiblintViolations = try violations(for: xibFiles)

            if !xiblintViolations.isEmpty {
                if inline {
                    inlineReport(violations: xiblintViolations, action: warnInlineAction)
                } else {
                    report(violations: xiblintViolations, action: markdownAction)
                }
            }

            return xiblintViolations
        } catch let error as XiblintError {
            print("Error: \(error.message)")
            return []
        } catch {
            print("Unexpected error")
            return []
        }
    }

    private static func violations(for files: [FilePath]) throws -> [Violation] {
        // Currently we are ignoring files, because there is no option to specify them on the fly
        // but let's keep the parameter so I can add --path option to xiblint later on ;-)
        let decoder = JSONDecoder()
        let outputJSON = shellExecutor.execute("xiblint", arguments: ["--reporter json"])
        do {
            return try decoder.decode([Violation].self, from: outputJSON.data(using: .utf8)!)
        } catch let error {
            throw XiblintError.serialization(json: outputJSON, error: error)
        }
    }

    private static func report(violations: [Violation], action: (String) -> Void) {
        var markdownMessage = """
                ### Xiblint found issues
                | File | Reason |
                | ---- | ------ |\n
                """
        markdownMessage += violations.map { $0.toMarkdown() }.joined(separator: "\n")
        action(markdownMessage)
    }

    private static func inlineReport(violations: [Violation], action: (String, String, Int) -> Void) {
        violations.forEach { violation in
            action(violation.error, violation.file, violation.line)
        }
    }
}

import XCTest
import Danger
import Foundation
@testable import DangerXiblint

class DangerXiblintTests: XCTestCase {

    // Current workaround for testing purposes.
    // Change to your path and uncomment when you are testing locally using Xcode.
//    let localPath = "/Users/lukaszmroz/Projects/OtherProjects/Libraries/DangerXiblint"
    let localPath = ""
    var executor: FakeShellExecutor!
    var danger: DangerDSL!
    var markdownMessage: String?

    override func setUp() {
        FileManager.default.changeCurrentDirectoryPath(localPath)
        executor = FakeShellExecutor()
        danger = parseDangerDSL(at: "Fixtures/danger_output.json")
        markdownMessage = nil
    }

    func testExecutesTheShell() {
        _ = Xiblint.lint(danger: danger, shellExecutor: executor)
        XCTAssertFalse(executor.invocations.isEmpty)
    }

    func testExecuteXiblintInInlineMode() {
        mockViolationJSON()
        var warns = [(String, String, Int)]()
        let warnAction: (String, String, Int) -> Void = { warns.append(($0, $1, $2)) }

        _ = Xiblint.lint(danger: danger, shellExecutor: executor, inline: true, warnInlineAction: warnAction)

        XCTAssertTrue(warns.first?.0 == "retina4_7: Simulated metrics (\"View As:\") must be one of: retina4_0, watch38")
        XCTAssertTrue(warns.first?.1 == "./.build/checkouts/RxSwift.git--5214619868639177420/RxExample/RxExample/iOS/Main.storyboard")
        XCTAssertTrue(warns.first?.2 == 3)
    }

    func testPrintsNoMarkdownIfNoViolations() {
        _ = Xiblint.lint(danger: danger, shellExecutor: executor)
        XCTAssertNil(markdownMessage)
    }

    func testViolations() {
        mockViolationJSON()
        let violations = Xiblint.lint(danger: danger, shellExecutor: executor, markdownAction: writeMarkdown)
        XCTAssertEqual(violations.count, 23)
    }

    func testMarkdownReporting() {
        mockViolationJSON()
        _ = Xiblint.lint(danger: danger, shellExecutor: executor, markdownAction: writeMarkdown)
        XCTAssertNotNil(markdownMessage)
        XCTAssertTrue(markdownMessage!.contains("Xiblint found issues"))
    }

    func mockViolationJSON() {
        let output = try! String(contentsOfFile: "Fixtures/sample_output.json")
        executor.output = output
    }

    func writeMarkdown(_ m: String) {
        markdownMessage = m
    }

    func parseDangerDSL(at path: String) -> DangerDSL {
        let dslJSONContents = FileManager.default.contents(atPath: path)!
        let decoder = JSONDecoder()
        if #available(OSX 10.12, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
        }
        return try! decoder.decode(DSL.self, from: dslJSONContents).danger
    }

    static var allTests = [
        ("testExecutesTheShell", testExecutesTheShell),
        ("testExecuteXiblintInInlineMode", testExecuteXiblintInInlineMode),
        ("testPrintsNoMarkdownIfNoViolations", testPrintsNoMarkdownIfNoViolations),
        ("testViolations", testViolations),
        ("testMarkdownReporting", testMarkdownReporting)
    ]
}

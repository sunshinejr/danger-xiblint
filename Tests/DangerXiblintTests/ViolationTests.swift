import XCTest
@testable import DangerXiblint

class ViolationTests: XCTestCase {
    func testDecoding() {
        // This is for testing, current workaround
        let localPath = "/Users/lukaszmroz/Projects/OtherProjects/Libraries/DangerXiblint"
        let data = NSData(contentsOfFile: localPath + "/Fixtures/sample_output.json")! as Data
        let violations = try! JSONDecoder().decode([Violation].self, from: data)

        XCTAssert(violations.count > 0)
    }


    static var allTests = [
        ("testDecoding", testDecoding)
    ]
}

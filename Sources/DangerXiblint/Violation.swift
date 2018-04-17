public struct Violation: Codable {
    
    let line: Int
    let rule: String
    let error: String

    private(set) var file: String

    public func toMarkdown() -> String {
        let formattedFile = file.split(separator: "/").last! + ":\(line)"
        return "\(formattedFile) | \(error) |"
    }

    mutating func update(file: String) {
        self.file = file
    }
}

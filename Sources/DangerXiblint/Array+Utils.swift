extension Array {
    var isNotEmpty: Bool {
        return !isEmpty

    }

    func inserted(_ newElement: Element, at i: Int) -> [Element] {
        var newArray = self
        newArray.insert(newElement, at: i)
        return newArray
    }
}

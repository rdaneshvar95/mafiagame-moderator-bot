import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(mafiagame_moderator_botTests.allTests),
    ]
}
#endif

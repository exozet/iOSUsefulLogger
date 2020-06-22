import XCTest
@testable import UsefulLogger
@testable import CoreUsefulSDK

final class UsefulLoggerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        AdvancedLogger.startListening()
        LoggingManager.info(message: "Test", domain: .app)
        
        let fileSize = AdvancedLogger.currentFileSize
        print(fileSize)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

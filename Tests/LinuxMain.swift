import XCTest

import SQLDataTests

var tests = [XCTestCaseEntry]()
tests += SQLDataTests.allTests()
XCTMain(tests)

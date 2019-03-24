//
//  SearchOperationTests.swift
//  20190309-AndrewFruth-NYCSchoolsTests
//
//  Created by Andrew Fruth on 3/23/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import XCTest
@testable import _0190309_AndrewFruth_NYCSchools

class SearchOperationTests: XCTestCase, SearchOperationDelegate {
    
    let operationQueue = OperationQueue()

    func testSchoolsSearchFilterWorked() {
        
        let testExpectation = XCTestExpectation(description: "finish search operation")
        let operation = SearchOperation(searchOperationDelegate: self, searchTerms: ["High", "School"]) { schools in
            if let schools = schools {
                let schoolsWithSearchTerms = schools.filter {$0.name.contains("High") && $0.name.contains("School")}
                XCTAssertTrue(schools.count == schoolsWithSearchTerms.count)
            }
            
            testExpectation.fulfill()
        }
        
        operationQueue.addOperation(operation)
        wait(for: [testExpectation], timeout: 30)
    }

    func willMakeSearchNetworkCall() {}
    func didFinishSearchNetworkCall() {}
}

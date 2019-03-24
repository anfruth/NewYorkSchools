//
//  SATScoresTests.swift
//  20190309-AndrewFruth-NYCSchoolsTests
//
//  Created by Andrew Fruth on 3/23/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import XCTest
@testable import _0190309_AndrewFruth_NYCSchools

class SATScoresTests: XCTestCase {
    
    var satScores: SATScores!

    override func setUp() {
        let satScoresDict = ["dbn": "123", "sat_critical_reading_avg_score": "500", "sat_math_avg_score": "550", "sat_writing_avg_score": "575"]
        let satData =  try! JSONSerialization.data(withJSONObject: satScoresDict, options: [])
        satScores = try? JSONDecoder().decode(SATScores.self, from: satData)
        
    }

    override func tearDown() {
        satScores = nil
    }

    func testDeserializationSucceeded() {
        XCTAssertTrue(satScores != nil)
    }

}

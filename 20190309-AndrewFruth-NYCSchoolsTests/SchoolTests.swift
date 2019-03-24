//
//  _0190309_AndrewFruth_NYCSchoolsTests.swift
//  20190309-AndrewFruth-NYCSchoolsTests
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import XCTest
@testable import _0190309_AndrewFruth_NYCSchools

class SchoolTests: XCTestCase {
    
    var school: School!

    override func setUp() {
        let schoolDict = ["dbn": "123", "school_name": "Akers High", "overview_paragraph": "Somthing about the school", "school_email": "something@aol.com", "phone_number": "555-555-5555"]
        let schoolData = try! JSONSerialization.data(withJSONObject: schoolDict, options: [])
        school = try? JSONDecoder().decode(School.self, from: schoolData)
    }

    override func tearDown() {
        school = nil
    }
    
    func testDeserializationSucceeded() {
        XCTAssertTrue(school != nil)
    }
    
    func testSchoolNeedsToRetrieveScoresNoSATScoreAvailable() {
        school.satScores = nil
        school.noScoreAvailable = false
        
        XCTAssertTrue(school.needsToRetrieveScores())
    }

    func testSchoolNeedsToRetrieveScoresHasSATScoreAvailable() {
        let satScoresDict = ["dbn": "123", "sat_critical_reading_avg_score": "500", "sat_math_avg_score": "550", "sat_writing_avg_score": "575"]
        let satData =  try! JSONSerialization.data(withJSONObject: satScoresDict, options: [])
        school.satScores = try! JSONDecoder().decode(SATScores.self, from: satData)
        
        school.noScoreAvailable = false
        
        XCTAssertFalse(school.needsToRetrieveScores())
    }
    
    func testSchoolNeedsToRetrieveScoresHasSATNoScoreAvailable() {
        let satScoresDict = ["dbn": "123", "sat_critical_reading_avg_score": "500", "sat_math_avg_score": "550", "sat_writing_avg_score": "575"]
        let satData =  try! JSONSerialization.data(withJSONObject: satScoresDict, options: [])
        school.satScores = try! JSONDecoder().decode(SATScores.self, from: satData)
        
        school.noScoreAvailable = true
        
        XCTAssertFalse(school.needsToRetrieveScores())
    }
    
    func testSchoolNeedsToRetrieveScoresNoSATNoScoreAvailable() {
        school.satScores = nil
        school.noScoreAvailable = true
        
        XCTAssertFalse(school.needsToRetrieveScores())
    }

}

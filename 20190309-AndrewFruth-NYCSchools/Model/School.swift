//
//  School.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

@objc final class School: NSObject, Decodable {
    @objc let name: String
    @objc var satScores: SATScores?
    
    let dbn: String
    var noScoreAvailable = false
    
    enum CodingKeys: String, CodingKey {
        case dbn
        case name = "school_name"
    }
    
    init(dbn: String, schoolName: String) {
        self.dbn = dbn
        self.name = schoolName
    }
    
    func needsToRetrieveScores() -> Bool {
        return satScores == nil && !noScoreAvailable
    }
}

//
//  School.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

class School: Codable {
    let dbn: String
    let name: String
    
    var satScores: SATScores?
    
    enum CodingKeys: String, CodingKey {
        case dbn
        case name = "school_name"
    }
    
    init(dbn: String, schoolName: String) {
        self.dbn = dbn
        self.name = schoolName
    }
}

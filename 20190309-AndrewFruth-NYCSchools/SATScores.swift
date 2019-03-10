//
//  SATScores.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

@objc final class SATScores: NSObject, Decodable {
    let dbn: String
    
    @objc let reading: NSNumber?
    @objc let math: NSNumber?
    @objc let writing: NSNumber?
    
    enum CodingKeys: String, CodingKey {
        case dbn
        case reading = "sat_critical_reading_avg_score"
        case math = "sat_math_avg_score"
        case writing = "sat_writing_avg_score"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.dbn = try values.decode(String.self, forKey: .dbn)
        
        let readingString = try values.decode(String.self, forKey: .reading)
        let mathString = try values.decode(String.self, forKey: .math)
        let writingString = try values.decode(String.self, forKey: .writing)
        
        if let reading = Int(readingString) {
            self.reading = NSNumber(value: reading)
        } else {
            self.reading = nil
        }
        
        if let math = Int(mathString) {
            self.math = NSNumber(value: math)
        } else {
            self.math = nil
        }
        
        if let writing = Int(writingString) {
            self.writing = NSNumber(value: writing)
        } else {
            self.writing = nil
        }
    }
}


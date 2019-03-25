//
//  SATScores.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

@objc final class SATScores: NSObject, Decodable {
    @objc let reading: NSNumber?
    @objc let math: NSNumber?
    @objc let writing: NSNumber?
    
    let dbn: String
    
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

        self.reading = SATScores.convertToNSNumber(with: readingString)
        self.math = SATScores.convertToNSNumber(with: mathString)
        self.writing = SATScores.convertToNSNumber(with: writingString)
    }
    
    static private func convertToNSNumber(with string: String) -> NSNumber? {
        if let intString = Int(string) {
            return NSNumber(value: intString)
        }
        
        return nil
    }
}

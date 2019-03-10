//
//  Networking.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

struct Networking {
    
    static let session = URLSession.shared
    static let schoolResultsPerCall = 50
    
    static func retrieveSchoolData(with schoolIndex: Int, completionHandler: @escaping ([School]) -> ()) {
        let schoolEndpoint = "https://data.cityofnewyork.us/resource/s3k6-pzi2.json"
        
        let orderParam = "$order=dbn"
        let limitParam = "$limit=50"
        let offset = "$offset=\(schoolIndex * schoolResultsPerCall)"
        
        let schoolEndpointWithParams = "\(schoolEndpoint)?\(orderParam)&\(limitParam)&\(offset)"
        
        guard let schoolURLWithParams = URL(string: schoolEndpointWithParams) else { return }
        
        let task = Networking.session.dataTask(with: schoolURLWithParams) { data, response, error in
            guard let data = data else { return }
            guard let schools = try? JSONDecoder().decode([School].self, from: data) else { return }
            
            completionHandler(schools)
        }
        
        task.resume()
    }
    
    static func retrieveAssociatedSATScores(from schools: ArraySlice<School>, completionHandler: @escaping ([SATScores]?, Error?) -> ()) {
        let satEndpoint = "https://data.cityofnewyork.us/resource/f9bf-2cp4.json"
        
        let schoolDBNs = schools.map { $0.dbn }
        
        var params = "?$where="
        for (i, dbn) in schoolDBNs.enumerated() {
            params.append("dbn=\"\(dbn)\"")
            if i < schoolDBNs.count - 1 {
                params.append(" OR ")
            }
        }
        
        guard let paramsEncoded = params.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let satEndPointWithParams = "\(satEndpoint)\(paramsEncoded)"
        
        guard let satURL = URL(string: satEndPointWithParams) else { return }
        
        let task = Networking.session.dataTask(with: satURL) { data, response, error in
            
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            
            guard let satScores = try? JSONDecoder().decode([SATScores].self, from: data) else {
                completionHandler(nil, error)
                return
            }
            
            completionHandler(satScores, error)
        }
        
        task.resume()
    }

}

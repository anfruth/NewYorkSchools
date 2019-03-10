//
//  Networking.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

struct Networking {
    
    static func retrieveSchoolData(schoolIndex: Int = 0, completionHandler: @escaping ([School]) -> ()) {
        let schoolEndpoint = "https://data.cityofnewyork.us/resource/s3k6-pzi2.json"
        let session = URLSession.shared
        
        let orderParam = "$order=dbn"
        let limitParam = "$limit=50"
        let offset = "$offset=\(schoolIndex)"
        
        let schoolEndpointWithParams = "\(schoolEndpoint)?\(orderParam)&\(limitParam)&\(offset)"
        
        guard let schoolURLWithParams = URL(string: schoolEndpointWithParams) else { return }
        
        let task = session.dataTask(with: schoolURLWithParams) { data, response, error in
            guard let data = data else { return }
            guard let schools = try? JSONDecoder().decode([School].self, from: data) else { return }
            
            completionHandler(schools)
        }
        
        task.resume()

        
    }

}

//
//  Networking.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

struct Networking {
    
    static let schoolResultsPerCall = 50
    private static let session = URLSession.shared
    private static let schoolEndpoint = "https://data.cityofnewyork.us/resource/s3k6-pzi2.json"
    private static let satEndpoint = "https://data.cityofnewyork.us/resource/f9bf-2cp4.json"
    
    // MARK: - Core Networking Methods
    static func retrieveSchoolData(with schoolPartitionIndex: Int, completionHandler: @escaping ([School]?) -> ()) {
        
        let schoolEndpointWithParams = Networking.generateSchoolEndpointWithParams(schoolPartitionIndex: schoolPartitionIndex)
        guard let schoolURLWithParams = URL(string: schoolEndpointWithParams) else {
            completionHandler(nil)
            return
        }
        
        Networking.makeSchoolDataNetworkCall(with: schoolURLWithParams, completionHandler: completionHandler)
    }
    
    static func retrieveAssociatedSATScores(from schools: ArraySlice<School>, completionHandler: @escaping ([SATScores]?, Error?) -> ()) {
        guard let encodedParmaas = generateEncodedParamsForSATScores(from: schools),
            let satURL = URL(string: "\(satEndpoint)\(encodedParmaas)") else {
                
            completionHandler(nil, nil)
            return
        }
        
        let task = Networking.session.dataTask(with: satURL) { data, response, error in
            handleSATScoresProcessing(from: data, error: error, completionHandler: completionHandler)
        }
        
        task.resume()
    }
    
    // MARK: - Helper Networking Methods
    private static func generateSchoolEndpointWithParams(schoolPartitionIndex: Int) -> String {
        let orderParam = "$order=dbn"
        let limitParam = "$limit=\(Networking.schoolResultsPerCall)"
        let offset = "$offset=\(schoolPartitionIndex * schoolResultsPerCall)"
        
        return "\(Networking.schoolEndpoint)?\(orderParam)&\(limitParam)&\(offset)"
    }
    
    private static func makeSchoolDataNetworkCall(with schoolURLWithParams: URL, completionHandler: @escaping ([School]?) -> ()) {
        
        let task = Networking.session.dataTask(with: schoolURLWithParams) { data, response, error in
            guard let data = data else {
                completionHandler(nil)
                return
            }
            guard let schools = try? JSONDecoder().decode([School].self, from: data) else {
                completionHandler(nil)
                return
            }
            
            completionHandler(schools)
        }
        
        task.resume()
    }
    
    private static func handleSATScoresProcessing(from data: Data?, error: Error?, completionHandler: @escaping ([SATScores]?, Error?) -> ()) {
        
        guard let data = data, let satScores = try? JSONDecoder().decode([SATScores].self, from: data) else {
            completionHandler(nil, error)
            return
        }
        
        completionHandler(satScores, error)
    }
    
    private static func generateEncodedParamsForSATScores(from schools: ArraySlice<School>) -> String? {
        let schoolDBNs = schools.map { $0.dbn }
        
        var params = "?$where="
        for (i, dbn) in schoolDBNs.enumerated() {
            params.append("dbn=\"\(dbn)\"")
            if i < schoolDBNs.count - 1 {
                params.append(" OR ")
            }
        }
        
        return params.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

}

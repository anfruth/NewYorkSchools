//
//  Networking.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

struct Networking {
    
    /*
    With more time I would have like to show a no connection state in
    the event of a lost internet connection. As it is now, more schools will not download
    if the internet is lost, but will download again when it is regained.
    */
    
    static let schoolResultsPerCall = 50
    private static let session = URLSession.shared
    private static let schoolEndpoint = "https://data.cityofnewyork.us/resource/s3k6-pzi2.json"
    private static let satEndpoint = "https://data.cityofnewyork.us/resource/f9bf-2cp4.json"
    
    // MARK: - Core Networking Methods
    static func retrieveSchoolData(with schoolPartitionIndex: Int, completionHandler: @escaping ([School]?) -> Void) {
        
        let endpoint = Networking.generateSchoolEndpointWithParams(schoolPartitionIndex: schoolPartitionIndex)
        guard let schoolURLWithParams = URL(string: endpoint) else {
            completionHandler(nil)
            return
        }
        
        Networking.makeSchoolDataNetworkCall(with: schoolURLWithParams, completionHandler: completionHandler)
    }
    
    static func retrieveAssociatedSATScores(from schools: ArraySlice<School>,
                                            completionHandler: @escaping ([SATScores]?, Error?) -> Void) {

        guard let encodedParmaas = generateEncodedParamsForSATScores(from: schools),
            let satURL = URL(string: "\(satEndpoint)\(encodedParmaas)") else {
                
            completionHandler(nil, nil)
            return
        }
        
        let task = Networking.session.dataTask(with: satURL) { data, _, error in
            handleSATScoresProcessing(from: data, error: error, completionHandler: completionHandler)
        }
        
        task.resume()
    }
    
    // search functionality, find schools with nameWords
    static func retrieveSchools(containing nameWords: [String], completionHandler: @escaping ([School]?) -> Void) {
        let endpoint = Networking.generateSchoolsByNameSearchEndpoint(with: nameWords)
        guard let schoolURLWithSearchParams = URL(string: endpoint) else {
            completionHandler(nil)
            return
        }
        
        Networking.makeSchoolDataNetworkCall(with: schoolURLWithSearchParams, completionHandler: completionHandler)
    }
    
    // MARK: - Helper Networking Methods
    
    private static func generateSchoolEndpointWithParams(schoolPartitionIndex: Int) -> String {
        let orderParam = "$order=school_name"
        let limitParam = "$limit=\(Networking.schoolResultsPerCall)"
        let offset = "$offset=\(schoolPartitionIndex * schoolResultsPerCall)"
        
        return "\(Networking.schoolEndpoint)?\(orderParam)&\(limitParam)&\(offset)"
    }
    
    private static func generateSchoolsByNameSearchEndpoint(with searchStrings: [String]) -> String {
        let limitParam = "$limit=\(Networking.schoolResultsPerCall)"
        let offset = "$offset=0"
        var whereParams = "$where="
        for (index, searchTerm) in searchStrings.enumerated() {
            whereParams.append("school_name like '%\(searchTerm)%'")
            if index < searchStrings.count - 1 {
                whereParams.append(" AND ")
            }
        }
        
        let query = "\(whereParams)&$order=school_name&\(limitParam)&\(offset)"
        if let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return "\(Networking.schoolEndpoint)?\(encodedQuery)"
        }
        
        return ""
    }
    
    private static func makeSchoolDataNetworkCall(with schoolURLWithParams: URL,
                                                  completionHandler: @escaping ([School]?) -> Void) {
        
        let task = Networking.session.dataTask(with: schoolURLWithParams) { data, _, _ in
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
    
    private static func handleSATScoresProcessing(from data: Data?, error: Error?,
                                                  completionHandler: @escaping ([SATScores]?, Error?) -> Void) {
        
        guard let data = data, let satScores = try? JSONDecoder().decode([SATScores].self, from: data) else {
            completionHandler(nil, error)
            return
        }
        
        completionHandler(satScores, error)
    }
    
    private static func generateEncodedParamsForSATScores(from schools: ArraySlice<School>) -> String? {
        let schoolDBNs = schools.map { $0.dbn }
        
        var params = "?$where="
        for (index, dbn) in schoolDBNs.enumerated() {
            params.append("dbn=\"\(dbn)\"")
            if index < schoolDBNs.count - 1 {
                params.append(" OR ")
            }
        }
        
        return params.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

}

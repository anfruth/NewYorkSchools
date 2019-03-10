//
//  SchoolsListViewController.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import UIKit

final class SchoolsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var schoolsListTableView: UITableView!
    var schools: [School] = []
    var schoolClicked: School?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        schoolsListTableView.dataSource = self
        schoolsListTableView.delegate = self
        populateTableWithSchoolData()
    }
    
    func populateTableWithSchoolData() {
        Networking.retrieveSchoolData() { [weak self] (schools) in
            DispatchQueue.main.async {
                self?.saveSchoolDataToCacheAndRefreshTable(with: schools)
            }
        }
    }
    
    private func saveSchoolDataToCacheAndRefreshTable(with schools: [School]) {
        self.schools.append(contentsOf: schools) // avoid duplicates
        schoolsListTableView.reloadData()
    }
    
    private func addSATDataToSchools(with schoolIndex: Int, completionHandler: @escaping () -> ()) {
        
        let schoolBeginIndex = schoolIndex * Networking.schoolResultsPerCall
        var schoolEndIndex: Int
        if schools.count < schoolBeginIndex + Networking.schoolResultsPerCall {
            schoolEndIndex = schools.count
        } else {
            schoolEndIndex = schoolBeginIndex + Networking.schoolResultsPerCall
        }
        
        let rangeOfSchools = schoolBeginIndex..<schoolEndIndex
        let schoolsToQuery = self.schools[rangeOfSchools]
        
        Networking.retrieveAssociatedSATScores(from: schoolsToQuery) { [weak self] (satScoresList, error) in
            
            guard let satScoresList = satScoresList, error == nil else {
                completionHandler()
                return
            }
            
            var satScoresDict: [String: SATScores] = [:]
            
            for satScores in satScoresList {
                satScoresDict[satScores.dbn] = satScores
            }

            DispatchQueue.main.async { [weak self] in
                self?.saveSATDataToCache(with: schoolsToQuery, scoresIDMapping: satScoresDict)
                completionHandler()
            }
        }
    }
    
    private func saveSATDataToCache(with schools: ArraySlice<School>, scoresIDMapping: [String: SATScores]) {
        
        for school in schools {
            if scoresIDMapping[school.dbn] == nil {
                school.noScoreAvailable = true
            } else {
                school.satScores = scoresIDMapping[school.dbn]
            }
        }

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let schoolCell = schoolsListTableView.dequeueReusableCell(withIdentifier: "schoolCell") {
            schoolCell.textLabel?.text = schools[indexPath.row].name
            return schoolCell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schools.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let schoolClicked = schools[indexPath.row]
        if schoolClicked.satScores == nil && !schoolClicked.noScoreAvailable {
            let schoolIndex = (indexPath.row / Networking.schoolResultsPerCall) % Networking.schoolResultsPerCall
            
            addSATDataToSchools(with: schoolIndex) { [weak self] in
                guard let schoolClicked = self?.schools[indexPath.row] else { return }
                self?.schoolClicked = schoolClicked
                self?.performSegue(withIdentifier: "showSchoolDetail", sender: self)
            }
        } else {
            self.schoolClicked = schools[indexPath.row]
            performSegue(withIdentifier: "showSchoolDetail", sender: self)
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSchoolDetail" {
            if let schoolDetailVC = segue.destination as? SchoolDetailViewController {
                schoolDetailVC.school = schoolClicked
            }
        }
    }


}


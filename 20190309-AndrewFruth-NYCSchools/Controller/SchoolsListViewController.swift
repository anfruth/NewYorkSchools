//
//  SchoolsListViewController.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import UIKit

final class SchoolsListViewController: UIViewController {

    @IBOutlet weak var transitionVCSpinner: UIActivityIndicatorView!
    @IBOutlet weak var transitionVCSpinnerSuperview: UIView!
    @IBOutlet weak var schoolsListTableView: UITableView!
    
    var schools: [School] = []
    var schoolClicked: School?
    lazy var footerSpinner: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    var populateTableWithSchoolDataUnderway = false
    var retrievedAllSchools = false
    
    let schoolDetailSegueID = "showSchoolDetail"
    let schoolCellID = "schoolCell"
    
    // MARK: - Overriden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        schoolsListTableView.dataSource = self
        schoolsListTableView.delegate = self
        footerSpinner.hidesWhenStopped = true
        schoolsListTableView.tableFooterView = footerSpinner
        
        populateTableWithSchoolData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == schoolDetailSegueID {
            if let schoolDetailVC = segue.destination as? SchoolDetailViewController {
                schoolDetailVC.school = schoolClicked
            }
        }
    }
    
    // MARK: - Retrieve And Handle School Data Methods
    private func populateTableWithSchoolData(with schoolIndex: Int = 0, completionHandler: (() -> ())? = nil) {
        
        populateTableWithSchoolDataUnderway = true
        Networking.retrieveSchoolData(with: schoolIndex) { [weak self] (schools) in
            if let vc = self {
                vc.handleProcessingSchoolData(with: schools, completionHandler: completionHandler)
            } else {
                completionHandler?()
            }
        }
    }
    
    private func handleProcessingSchoolData(with schools: [School]?, completionHandler: (() -> ())?) {
        DispatchQueue.main.async { [weak self] in
            if let schools = schools {
                if schools.count == 0 || schools.count < Networking.schoolResultsPerCall { self?.retrievedAllSchools = true }
                self?.saveSchoolDataToCacheAndRefreshTable(with: schools)
            }
            
            self?.populateTableWithSchoolDataUnderway = false
            completionHandler?()
        }
    }
    
    private func saveSchoolDataToCacheAndRefreshTable(with schools: [School]) {
        self.schools.append(contentsOf: schools) // avoid duplicates
        schoolsListTableView.reloadData()
    }
    
    // MARK: - Core Retrieve And Handle SAT Scores Methods
    
    private func handleRetrievingSATScores(with schoolClicked: School, indexPath: IndexPath) {
        let schoolParitionIndex = getSchoolPartitionIndex(from: indexPath.row)
        
        startTransitionSpinner()
        addSATDataToSchools(with: schoolParitionIndex) { [weak self] error in
            self?.stopTransitionSpinner()
            self?.performDetailVCSegue(with: schoolClicked)
        }
    }
    
    private func addSATDataToSchools(with schoolPartitionIndex: Int, completionHandler: @escaping (Error?) -> ()) {
        let schoolsToQuery = getSchoolsToQueryForSATScores(with: schoolPartitionIndex)
        
        Networking.retrieveAssociatedSATScores(from: schoolsToQuery) { [weak self] (satScoresList, error) in
            if let vc = self {
                vc.handleProcessingSATScores(for: schoolsToQuery, satScoresList: satScoresList, error: error, completionHandler: completionHandler)
            } else {
                completionHandler(error)
            }
        }
    }
    
    private func handleProcessingSATScores(for schoolsToQuery: ArraySlice<School>, satScoresList: [SATScores]?, error: Error?, completionHandler: @escaping (Error?) -> () ) {
        
        guard let satScoresList = satScoresList, error == nil else {
            DispatchQueue.main.async { completionHandler(error) }
            return
        }
        
        let satScoresDict = setUpSchoolToSATScoreMapping(satScoresList: satScoresList)
        DispatchQueue.main.async { [weak self] in
            self?.saveSATDataToCache(with: schoolsToQuery, scoresIDMapping: satScoresDict)
            completionHandler(error)
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
    
    // MARK: - Helper SAT Scores Methods
    private func getSchoolsToQueryForSATScores(with schoolParitionIndex: Int) -> ArraySlice<School> {
        
        let schoolBeginIndex = schoolParitionIndex * Networking.schoolResultsPerCall
        let schoolEndIndex = getSchoolEndIndex(with: schoolBeginIndex)
        
        let rangeOfSchools = schoolBeginIndex..<schoolEndIndex
        return schools[rangeOfSchools]
    }
    
    private func setUpSchoolToSATScoreMapping(satScoresList: [SATScores]) -> [String: SATScores] {
        var satScoresDict: [String: SATScores] = [:]
        
        for satScores in satScoresList {
            satScoresDict[satScores.dbn] = satScores
        }
        
        return satScoresDict
    }
    
    private func getSchoolEndIndex(with schoolBeginIndex: Int) -> Int {
        
        var schoolEndIndex: Int
        if schools.count < schoolBeginIndex + Networking.schoolResultsPerCall {
            schoolEndIndex = schools.count
        } else {
            schoolEndIndex = schoolBeginIndex + Networking.schoolResultsPerCall
        }
        
        return schoolEndIndex
    }
    
    // MARK: - Handle Transition Spinner Methods
    
    private func startTransitionSpinner() {
        transitionVCSpinner.isHidden = false
        transitionVCSpinner.startAnimating()
        transitionVCSpinnerSuperview.isHidden = false
    }
    
    private func stopTransitionSpinner() {
        transitionVCSpinnerSuperview.isHidden = true
        transitionVCSpinner.stopAnimating()
    }
    
    // MARK: - Small Helper Methods
    
    private func performDetailVCSegue(with schoolClicked: School) {
        self.schoolClicked = schoolClicked
        performSegue(withIdentifier: schoolDetailSegueID, sender: self)
    }
    
    private func getSchoolPartitionIndex(from schoolIndex: Int) -> Int {
        return (schoolIndex / Networking.schoolResultsPerCall) % Networking.schoolResultsPerCall
    }
    
    private func needToDownloadMoreSchools(schoolsCount: Int, indexPath: IndexPath) -> Bool {
        let lastDownloadCellDisplayed = lastDownloadedCellWillDisplay(schoolsCount: schoolsCount, indexPath: indexPath)
        return lastDownloadCellDisplayed && !populateTableWithSchoolDataUnderway && !retrievedAllSchools
    }
    
    private func lastDownloadedCellWillDisplay(schoolsCount: Int, indexPath: IndexPath) -> Bool {
        return schoolsCount - 1 == indexPath.row
    }
}

// MARK: - School List Table Data Source
extension SchoolsListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let schoolCell = schoolsListTableView.dequeueReusableCell(withIdentifier: schoolCellID) {
            schoolCell.textLabel?.text = schools[indexPath.row].name
            return schoolCell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schools.count
    }
    
}

// MARK: - School List Table Delegate
extension SchoolsListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let schoolClicked = schools[indexPath.row]
        
        if schoolClicked.needsToRetrieveScores() {
            handleRetrievingSATScores(with: schoolClicked, indexPath: indexPath)
        } else {
            performDetailVCSegue(with: schoolClicked)
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let schoolsCount = schools.count
        
        if needToDownloadMoreSchools(schoolsCount: schoolsCount, indexPath: indexPath) {
            let schoolParitionIndex = getSchoolPartitionIndex(from: schoolsCount)
            
            footerSpinner.startAnimating()
            populateTableWithSchoolData(with: schoolParitionIndex) { [weak self] in
                self?.footerSpinner.stopAnimating()
            }
        }
    }
}

//
//  SchoolsListViewController.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import UIKit

final class SchoolsListViewController: UIViewController {

    @IBOutlet private weak var schoolsListTableView: UITableView!
    @IBOutlet private weak var noResultsLabel: UILabel!
    
    private lazy var footerSpinner: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    private lazy var mainSpinner: MainSpinner = Bundle.main.loadNibNamed("MainSpinner", owner: nil, options: nil)![0] as! MainSpinner
    
    private var resultsTableController: SearchResultsTableViewController?
    
    private var schools: [School] = []
    private var schoolClicked: School?
    
    private var populateTableWithSchoolDataUnderway = false
    private var retrievedAllSchools = false
    
    private let schoolDetailSegueID = "showSchoolDetail"
    private let schoolCellID = "schoolCell"
    
    private var searchController: UISearchController?
    private var waitedIntervalAfterSearch = false
    private let searchOperationQueue = OperationQueue()
    
    
    // MARK: - Overriden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        schoolsListTableView.dataSource = self
        schoolsListTableView.delegate = self
        footerSpinner.hidesWhenStopped = true
        schoolsListTableView.tableFooterView = footerSpinner
        
        populateTableWithSchoolData() { [weak self] in
            self?.handlePopulatingSchoolDataComplete()
        }
        
        setupSearchController()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == schoolDetailSegueID {
            if let schoolDetailVC = segue.destination as? SchoolDetailViewController {
                schoolDetailVC.school = schoolClicked
            }
        }
    }
    
    @IBAction func refreshAllResults(_ sender: UIBarButtonItem) {
        schools = []
        retrievedAllSchools = false
        populateTableWithSchoolData() { [weak self] in
            self?.handlePopulatingSchoolDataComplete()
        }
    }
    
    private func setupSearchController() {
        resultsTableController = SearchResultsTableViewController()
        resultsTableController?.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.autocapitalizationType = .none
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController?.dimsBackgroundDuringPresentation = false
        
        definesPresentationContext = true
        searchOperationQueue.maxConcurrentOperationCount = 1
    }
    
    
    // MARK: - Retrieve And Handle School Data Methods
    private func populateTableWithSchoolData(with schoolIndex: Int = 0, completionHandler: (() -> ())? = nil) {
        if schoolIndex == 0 { mainSpinner.start(viewAddingSpinner: view) }
        
        populateTableWithSchoolDataUnderway = true
        Networking.retrieveSchoolData(with: schoolIndex) { [weak self] (schools) in
            if schoolIndex == 0 {
                DispatchQueue.main.async { self?.mainSpinner.stop() }
            }
            
            if let vc = self {
                vc.handleProcessingSchoolData(with: schools, completionHandler: completionHandler)
            } else {
                completionHandler?()
            }
        }
    }
    
    private func handlePopulatingSchoolDataComplete() {
        if  schools.isEmpty {
            noResultsLabel.isHidden = false
            schoolsListTableView.isHidden = true
        } else {
            let firstIndexPath = IndexPath(row: 0, section: 0)
            schoolsListTableView.scrollToRow(at: firstIndexPath, at: UITableView.ScrollPosition.none, animated: true)
            noResultsLabel.isHidden = true
            schoolsListTableView.isHidden = false
        }
    }
    
    private func handleProcessingSchoolData(with schools: [School]?, completionHandler: (() -> ())?) {
        DispatchQueue.main.async { [weak self] in
            if let schools = schools {
                if schools.count == 0 || schools.count < Networking.schoolResultsPerCall { self?.retrievedAllSchools = true }
                self?.saveSchoolDataToCacheAndRefreshTable(with: schools)
                completionHandler?()
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
        
        mainSpinner.start(viewAddingSpinner: view)
        addSATDataToSchools(with: schoolParitionIndex) { [weak self] error in
            self?.mainSpinner.stop()
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
    
    private func addSATDataToSchool(with school: School, completionHandler: @escaping (Error?) -> ()) {
        let schools: ArraySlice<School> = [school]
        
        Networking.retrieveAssociatedSATScores(from: schools) { [weak self] (satScoresList, error) in
            if let vc = self {
                vc.handleProcessingSATScores(for: schools, satScoresList: satScoresList, error: error, completionHandler: completionHandler)
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
        searchController?.searchBar.resignFirstResponder()
        guard let schoolClicked = getSchoolClicked(tableView: tableView, indexPath: indexPath) else { return }
        viewSchoolDetails(with: schoolClicked, tableView: tableView, indexPath: indexPath)
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
    
    private func getSchoolClicked(tableView: UITableView, indexPath: IndexPath) -> School? {
        var schoolClicked: School?
        
        if tableView === schoolsListTableView {
            schoolClicked = schools[indexPath.row]
        } else if let resultsTableController = resultsTableController {
            schoolClicked = resultsTableController.filteredSchools[indexPath.row]
        }
        
        return schoolClicked
    }
    
    private func viewSchoolDetails(with schoolClicked: School, tableView: UITableView, indexPath: IndexPath) {
        if schoolClicked.needsToRetrieveScores() {
            retreiveScoresBased(on: tableView, schoolClicked: schoolClicked, indexPath: indexPath)
        } else {
            performDetailVCSegue(with: schoolClicked)
        }
    }
    
    private func retreiveScoresBased(on tableView: UITableView, schoolClicked: School, indexPath: IndexPath) {
        
        if tableView === schoolsListTableView {
            handleRetrievingSATScores(with: schoolClicked, indexPath: indexPath)
            
        } else if let resultsTableController = resultsTableController {
            mainSpinner.start(viewAddingSpinner: resultsTableController.view)
            addSATDataToSchool(with: schoolClicked) { [weak self] error in
                self?.mainSpinner.stop()
                self?.performDetailVCSegue(with: schoolClicked)
            }
        }
    }
    
}

// MARK: - UISearchResultsUpdating
extension SchoolsListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        searchOperationQueue.cancelAllOperations()
        guard let searchWords = getSearchWordsFromSearchBar(searchController: searchController) else {
            resultsTableController?.filteredSchools.removeAll()
            resultsTableController?.tableView.reloadData()
            return
        }

        enqueueSearchOperation(searchWords: searchWords)
    }
    
    private func getSearchWordsFromSearchBar(searchController: UISearchController) -> [Substring]? {
        let whitespaceCharacterSet = CharacterSet.whitespaces
        if let strippedString = searchController.searchBar.text?.trimmingCharacters(in: whitespaceCharacterSet) {
            let capString = strippedString.capitalized
            return capString.split(separator: " ")
        }
        
        return nil
    }
    
    private func enqueueSearchOperation(searchWords: [Substring]) {
        
        let fullSearchStrings: [String] = searchWords.map { String($0) }
        resultsTableController?.allSearchStrings = searchWords.map { String($0) }
        let operation: SearchOperation = SearchOperation(searchOperationDelegate: self, searchTerms: fullSearchStrings) { [weak self] schools in
           self?.handleCompletedSearchOperation(schools: schools)
        }
        
        searchOperationQueue.addOperation(operation)
    }
    
    private func handleCompletedSearchOperation(schools: [School]?) {
        
        DispatchQueue.main.async { [weak self] in
            if let resultsTableController = self?.resultsTableController, let schools = schools {
                resultsTableController.filteredSchools = schools
                resultsTableController.tableView.reloadData()
            }
        }
    }

}

// MARK: - SearchOperationDelegate
extension SchoolsListViewController: SearchOperationDelegate {
    
    func willMakeSearchNetworkCall() {
        DispatchQueue.main.async { [weak self] in
            guard let resultsVCView = self?.resultsTableController?.view else { return }
            self?.mainSpinner.start(viewAddingSpinner: resultsVCView)
        }
    }
    
    func didFinishSearchNetworkCall() {
        DispatchQueue.main.async { [weak self] in
            self?.mainSpinner.stop()
        }
    }
    
}

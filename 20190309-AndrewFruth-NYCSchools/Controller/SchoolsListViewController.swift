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
    private lazy var mainSpinner: MainSpinner? = Bundle.main.loadNibNamed("MainSpinner", owner: nil, options: nil)?[0] as? MainSpinner
    
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
    
    private let tableViewPullUpThreshold: CGFloat = -30
    
    
    // MARK: - Overriden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        schoolsListTableView.dataSource = self
        schoolsListTableView.delegate = self
        footerSpinner.hidesWhenStopped = true
        schoolsListTableView.tableFooterView = footerSpinner
        if let bolderFont = UIFont(name: "SanFranciscoDisplay-Bold", size: 20) {
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: bolderFont]
        }
        
        populateTableWithSchoolData() { [weak self] in
            self?.handlePopulatingSchoolDataComplete()
        }
        
        setupSearchController()
        searchOperationQueue.maxConcurrentOperationCount = 1
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == schoolDetailSegueID {
            if let schoolDetailVC = segue.destination as? SchoolDetailViewController {
                schoolDetailVC.school = schoolClicked
            }
        }
    }
    
    // clears all schools data and repopulates first 50 results upon clicking refresh button
    @IBAction func refreshAllResults(_ sender: UIBarButtonItem) {
        schools.removeAll()
        retrievedAllSchools = false
        populateTableWithSchoolData() { [weak self] in
            self?.handlePopulatingSchoolDataComplete()
        }
    }
    
    
    /**
     Creates a personalized greeting for a recipient.
        Sets up the search controller and bar.
     */
    private func setupSearchController() {
        resultsTableController = SearchResultsTableViewController()
        resultsTableController?.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.autocapitalizationType = .none
        searchController?.searchBar.returnKeyType = .done
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        definesPresentationContext = true
    }
    
    
    // MARK: - Retrieve And Handle School Data Methods
     /**
     Populates the school list table view with schools.
     
     - Parameter schoolIndex: The partition index to decide what schools to download.
     - Parameter completionHandler: The handler to be executed after school data is finished being processed.
     
     The schoolIndex decides what group of results to display. For example, if the backend database has 400 possible
     schools, the partition index tells the app which part of those 400 to download. Since Networking.schoolsPerCall is 50,
     a schoolIndex of 0 would download the first 50 results. An index of 1 would download the 50 results after that.
     */
    private func populateTableWithSchoolData(with schoolIndex: Int = 0, completionHandler: (() -> ())? = nil) {
        if schoolIndex == 0 { mainSpinner?.start(viewAddingSpinner: view) }
        
        populateTableWithSchoolDataUnderway = true
        Networking.retrieveSchoolData(with: schoolIndex) { [weak self] (schools) in
            if schoolIndex == 0 {
                DispatchQueue.main.async { self?.mainSpinner?.stop() }
            }
            
            if let vc = self {
                vc.handleProcessingSchoolData(with: schools, completionHandler: completionHandler)
            } else {
                completionHandler?()
            }
        }
    }
    
    /**
     Sets up and hides views after the initial school results are populated.
     In case of no network connection on loading of the app or API failure, I added in a no results label.
     */
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
    
    /**
     Saves schools to memory and refreshes the school list table.
     
     - Parameter schools: The schools to save.
     - Parameter completionHandler: The handler to be executed after schools are saved.
     
     The Socrata API does not give a count of total schools when paginating. Therefore, the flag "retrievedAllSchools" is
     used to determine if there are more results to fetch. This is not ideal because if Socrata ever returned an empty array
     due to an API error, the app would think there are no more results.
     
     It was necessary because the app doesn't want to continue
     to make API calls repeatedly to check if there are more results when scrolling through the table. The best solution would be to
     have some sort of API call that provides the total count while paginating. Network failures will not make "retrievedAllSchools"
     true because the schools array will be nil.
     */
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
    
    // helper method for the above
    private func saveSchoolDataToCacheAndRefreshTable(with schools: [School]) {
        self.schools.append(contentsOf: schools) // avoid duplicates
        schoolsListTableView.reloadData()
    }
    
    // MARK: - Core Retrieve And Handle SAT Scores Methods
    
    /**
     Adds SAT scores to schools and shows the clicked school's detail page.
     
     - Parameter schoolClicked: The school clicked.
     - Parameter indexPath: The indexPath of the cell clicked.
     
     Upon clicking a school, this method will download the SAT scores of that school and some surrounding schools to save on
     extra network calls if surrounding schools are clicked as well. Some schools may not have SAT scores or the SAT network call
     could fail. If either case happens, that school detail page will show SAT scores as unavailable.
     */
    private func handleRetrievingSATScores(with schoolClicked: School, indexPath: IndexPath) {
        let schoolParitionIndex = getSchoolPartitionIndex(from: indexPath.row)
        
        mainSpinner?.start(viewAddingSpinner: view)
        addSATDataToSchools(with: schoolParitionIndex) { [weak self] error in
            self?.mainSpinner?.stop()
            self?.performDetailVCSegue(with: schoolClicked)
        }
    }
    
    // helper method for the above.
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
    
    // helper method for the above.
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
    
    // MARK: - Core Retrieve And Handle SAT Scores Methods
    
    /**
     Saves the SAT score data to the appropriate schools.
     
     - Parameter schoolsToQuery: The schools to get SAT scores for.
     - Parameter satScoresList: The returned SAT scores list from the API call.
     - Parameter error: Any error from the network API call.
     - Parameter completionHandler: Handler to be called after processing SAT scores is complete.
     
     Relates unique dbn identifier of schools to SAT scores. Uses dictionary rather than repeated array traversal for added
     efficiency.
     */
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
    
    // MARK: - Helper SAT Scores Methods
    private func saveSATDataToCache(with schools: ArraySlice<School>, scoresIDMapping: [String: SATScores]) {
        
        for school in schools {
            if scoresIDMapping[school.dbn] == nil {
                school.noScoreAvailable = true
            } else {
                school.satScores = scoresIDMapping[school.dbn]
            }
        }
    }
    
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
    
    private func needToDownloadMoreSchools(schoolsCount: Int, indexPath: IndexPath?) -> Bool {
        
        if let indexPath = indexPath {
            let lastDownloadCellDisplayed = lastDownloadedCellWillDisplay(schoolsCount: schoolsCount, indexPath: indexPath)
            return lastDownloadCellDisplayed && !populateTableWithSchoolDataUnderway && !retrievedAllSchools
            
        } else {
            let tableViewPulledUp = isTableViewPulledUp()
            return tableViewPulledUp && !populateTableWithSchoolDataUnderway && !retrievedAllSchools
        }
    }
    
    private func lastDownloadedCellWillDisplay(schoolsCount: Int, indexPath: IndexPath) -> Bool {
        return schoolsCount - 1 == indexPath.row
    }
    
    // Thanks to: https://stackoverflow.com/questions/27190848/how-to-show-pull-to-refresh-element-at-the-bottom-of-the-uitableview-in-swift
    private func isTableViewPulledUp() -> Bool {
        let currentOffset = schoolsListTableView.contentOffset.y
        let maxOffset = schoolsListTableView.contentSize.height - schoolsListTableView.frame.size.height
        let amountPulledUp = maxOffset - currentOffset
        
        return amountPulledUp <= tableViewPullUpThreshold
    }
    
    private func handleDownloadingMoreSchools(indexPath: IndexPath?) {
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

// MARK: - School List Table Data Source
extension SchoolsListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let schoolCell = schoolsListTableView.dequeueReusableCell(withIdentifier: schoolCellID) {
            if schools.count > indexPath.row {
                schoolCell.textLabel?.text = schools[indexPath.row].name
            }
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
        handleDownloadingMoreSchools(indexPath: indexPath)
    }
    
    // varies based on regular table vs. filtered from search table
    private func getSchoolClicked(tableView: UITableView, indexPath: IndexPath) -> School? {
        var schoolClicked: School?
        
        if tableView === schoolsListTableView {
            if schools.count > indexPath.row {
                schoolClicked = schools[indexPath.row]
            }
            
        } else if let resultsTableController = resultsTableController {
            if resultsTableController.filteredSchools.count > indexPath.row {
                schoolClicked = resultsTableController.filteredSchools[indexPath.row]
            }
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
    
    // If clicking from the search table, a new api call is guaranteed when clicking a school. A more complex architecture
    // could try to detect whether the information was already cached, but for the sake of time, search is back end based entirely.
    private func retreiveScoresBased(on tableView: UITableView, schoolClicked: School, indexPath: IndexPath) {
        
        if tableView === schoolsListTableView {
            handleRetrievingSATScores(with: schoolClicked, indexPath: indexPath)
            
        } else if let resultsTableController = resultsTableController {
            mainSpinner?.start(viewAddingSpinner: resultsTableController.view)
            addSATDataToSchool(with: schoolClicked) { [weak self] error in
                self?.mainSpinner?.stop()
                self?.performDetailVCSegue(with: schoolClicked)
            }
        }
    }
    
}

// a sort of pull to refresh at the bottom of the table view in case the previous download failed.
extension SchoolsListViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        handleDownloadingMoreSchools(indexPath: nil) // will only download if needed
    }
    
}

// MARK: - UISearchResultsUpdating
extension SchoolsListViewController: UISearchResultsUpdating {
    
    /*
     I designed the search so that a new query would initiate every 0.5 seconds after finishing typing unless the query was blank.
     However, given the nature of asynchronous network calls, it's important to avoid the case where multiple calls are made, but
     then returned in a different order from which they were made. I didn't want "Aca" results to show up after the user finished
     typing in "Academy." In addition, I wanted to reduce network calls as much as possible while maintaining a responsive search
     experience. To do so I created a serial operation queue with a maximum of one operation in the queue. Any previous searches are
     immediately cancelled and results (if networking was already underway) are ignored.
    */
    func updateSearchResults(for searchController: UISearchController) {
        
        searchOperationQueue.cancelAllOperations()
        guard let searchWords = getSearchWordsFromSearchBar(searchController: searchController) else {
            resultsTableController?.filteredSchools.removeAll()
            resultsTableController?.tableView.reloadData()
            return
        }

        enqueueSearchOperation(searchWords: searchWords)
    }
    
    /*
     Detects the search words and splits up words by white space. That way a search of "High School" can
     highlight a school name of "High Hill Elementary School" rather than simply "Hill High School".
     Socrata's search API is unfortunately case sensitive, and because most of the school names are
     capitalized, I automatically capitalize all search terms. However, some words such as "and" or "for"
     are lower case and, therefore, will not show results unless the school name contains "And" or "For".
     */
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
            self?.mainSpinner?.start(viewAddingSpinner: resultsVCView)
        }
    }
    
    func didFinishSearchNetworkCall() {
        DispatchQueue.main.async { [weak self] in
            self?.mainSpinner?.stop()
        }
    }
    
}

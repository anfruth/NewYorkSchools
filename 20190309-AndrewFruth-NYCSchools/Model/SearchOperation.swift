//
//  SearchOperation.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/17/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

class SearchOperation: Operation {
    
    weak var schoolsListVC: SchoolsListViewController?
    let searchTerms: [String]
    let completionHandler: (() -> ())?
    
    private var _isExecuting: Bool {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    private var _isFinished: Bool {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return _isFinished
    }
    
    init(schoolsListVC: SchoolsListViewController, searchTerms: [String], completionHandler: (() -> ())?) {
        _isExecuting = false
        _isFinished = false
        
        self.schoolsListVC = schoolsListVC
        self.searchTerms = searchTerms
        self.completionHandler = completionHandler
        
        super.init()
    }
    
    override func start() {
        
        if isCancelled {
            _isExecuting = false
            _isFinished = true
            print("finish 1")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
   
            if !self.isCancelled {
                print(self.searchTerms)
                
                guard let spinner = Bundle.main.loadNibNamed("MainSpinner", owner: nil, options: nil)?[0] as? MainSpinner else {
                    return
                }
                spinner.start(viewAddingSpinner: self.schoolsListVC!.resultsTableController!.view)
                
                Networking.retrieveSchools(containing: self.searchTerms) { schools in
                    DispatchQueue.main.async {
                        spinner.stop()
                    }
                    
                    if self.isCancelled {
                        self._isExecuting = false
                        self._isFinished = true
                        self.completionHandler?()
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if let schools = schools {
                            self.schoolsListVC?.resultsTableController?.filteredSchools = schools
                            self.schoolsListVC?.resultsTableController?.tableView.reloadData()
                        }
                        
                        self._isExecuting = false
                        self._isFinished = true
                        self.completionHandler?()
                        print("finish 2")
                    }
                }
            } else {
                self._isExecuting = false
                self._isFinished = true
                self.completionHandler?()
                print("finish 3")
            }
        }
        
    }
    
}

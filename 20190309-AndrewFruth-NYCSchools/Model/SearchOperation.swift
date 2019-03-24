//
//  SearchOperation.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/17/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

final class SearchOperation: Operation {
    
    typealias SchoolCompletionHandler = (([School]?) -> ())?
    
    private weak var searchOperationDelegte: SearchOperationDelegate?
    private let searchTerms: [String]
    private let completionHandler: (([School]?) -> ())?
    private let secondsDelayFromTypingSearch = 0.5
    private let isExecutingKey = "isExecuting"
    private let isFinishedKey = "isFinished"
    
    private var _isExecuting: Bool {
        willSet {
            willChangeValue(forKey: isExecutingKey)
        }
        didSet {
            didChangeValue(forKey: isExecutingKey)
        }
    }
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    private var _isFinished: Bool {
        willSet {
            willChangeValue(forKey: isFinishedKey)
        }
        didSet {
            didChangeValue(forKey: isFinishedKey)
        }
    }
    
    override var isFinished: Bool {
        return _isFinished
    }
    
    init(searchOperationDelegate: SearchOperationDelegate, searchTerms: [String], completionHandler: SchoolCompletionHandler) {
        _isExecuting = false
        _isFinished = false
        
        self.searchOperationDelegte = searchOperationDelegate
        self.searchTerms = searchTerms
        self.completionHandler = completionHandler
        
        super.init()
    }
    
    override func start() {
        if isCancelledAndFinish() { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelayFromTypingSearch) {
            if !self.isCancelled {
                self.runOperationAfterDelay()
            } else {
                self.finishOp(schools: nil)
            }
        }
        
    }
    
    private func runOperationAfterDelay() {
        searchOperationDelegte?.willMakeSearchNetworkCall()
        Networking.retrieveSchools(containing: searchTerms) { schools in
            
            self.searchOperationDelegte?.didFinishSearchNetworkCall()
            if self.isCancelledAndFinish() { return }
            self.finishOp(schools: schools)
        }
    }
    
    private func isCancelledAndFinish() -> Bool {
        if isCancelled {
            finishOp(schools: nil)
            return true
        }
        return false
    }
    
    private func finishOp(schools: [School]?) {
        self._isExecuting = false
        self._isFinished = true
        self.completionHandler?(schools)
    }
    
}

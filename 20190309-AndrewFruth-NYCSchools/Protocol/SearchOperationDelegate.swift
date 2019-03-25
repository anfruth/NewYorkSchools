//
//  SearchOperationDelegate.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/18/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import Foundation

protocol SearchOperationDelegate: class {
    
    func willMakeSearchNetworkCall()
    func didFinishSearchNetworkCall()
    
}

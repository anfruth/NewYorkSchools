//
//  SearchResultsTableViewController.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/16/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import UIKit

final class SearchResultsTableViewController: UITableViewController {
    
    
    var filteredSchools: [School] = []
    var allSearchStrings: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "schoolCell")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return filteredSchools.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if let schoolCell = tableView.dequeueReusableCell(withIdentifier: "schoolCell") {
            
            let schoolNameText = filteredSchools[indexPath.row].name
            let attributedSchoolName = NSMutableAttributedString(string: schoolNameText, attributes: nil)
            var rangesToBold: [NSRange] = []
            
            for searchString in allSearchStrings {
                rangesToBold.append(contentsOf: (schoolNameText as NSString).getRanges(of: searchString))
            }
            
            for range in rangesToBold {
                attributedSchoolName.setAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)], range: range)
            }
            
            
            schoolCell.textLabel?.attributedText = attributedSchoolName
            schoolCell.textLabel?.numberOfLines = 0
            return schoolCell
        }
        
        return UITableViewCell()
    }
}

// adopted from https://stackoverflow.com/questions/7033574/find-all-locations-of-substring-in-nsstring-not-just-first/7033787
// not worried about getting overlapping substrings
extension NSString {
    
    func getRanges(of substring: String) -> [NSRange] {
        var ranges: [NSRange] = []
        var searchRange = NSMakeRange(0, length)
        var foundRange: NSRange
        
        while (searchRange.location < length) {
            searchRange.length = length - searchRange.location
            foundRange = range(of: substring, options: [], range: searchRange)
            
            if foundRange.location != NSNotFound {
                ranges.append(foundRange)
                searchRange.location = foundRange.location + foundRange.length
            } else {
                break
            }
        }
        
        return ranges
    }
}

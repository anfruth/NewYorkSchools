//
//  SchoolsListViewController.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import UIKit

class SchoolsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var schoolsListTableView: UITableView!
    var schools: [School] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        schoolsListTableView.dataSource = self
        schoolsListTableView.delegate = self
        populateTableWithSchoolData()
    }
    
    func populateTableWithSchoolData() {
        Networking.retrieveSchoolData() { [weak self] (schools) in
            self?.schools = schools
            DispatchQueue.main.async {
                self?.schoolsListTableView.reloadData()
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


}


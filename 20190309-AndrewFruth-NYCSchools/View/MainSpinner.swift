//
//  MainSpinner.swift
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/17/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

import UIKit

class MainSpinner: UIView {

    @IBOutlet weak var transitionVCSpinner: UIActivityIndicatorView!
    @IBOutlet weak var transitionVCSpinnerSuperview: UIView!
    
    private func setupConstraints() {
        if let superview = superview {
            widthAnchor.constraint(equalToConstant: 150).isActive = true
            heightAnchor.constraint(equalToConstant: 150).isActive = true
            centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
            centerYAnchor.constraint(equalTo: superview.centerYAnchor, constant: superview.bounds.origin.y).isActive = true
            translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func start(viewAddingSpinner: UIView) {
        viewAddingSpinner.addSubview(self)
        setupConstraints()
        transitionVCSpinner.startAnimating()
    }
    
    func stop() {
        transitionVCSpinner.stopAnimating()
        removeFromSuperview()
    }

}

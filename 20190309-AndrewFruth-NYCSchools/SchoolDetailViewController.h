//
//  SchoolDetailViewController.h
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

#import <UIKit/UIKit.h>

@class School;

@interface SchoolDetailViewController : UITableViewController

@property (strong, nonatomic, nullable) School *school;

@end


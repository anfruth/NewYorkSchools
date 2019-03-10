//
//  SchoolDetailViewController.m
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

#import "SchoolDetailViewController.h"
#import "_0190309_AndrewFruth_NYCSchools-Swift.h"

@interface SchoolDetailViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *satWritingCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *satReadingCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *satMathCell;

@end

@implementation SchoolDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.satWritingCell.textLabel.text = [NSString stringWithFormat: @"Writing SAT: %@",  self.school.satScores.writing.stringValue];
    self.satReadingCell.textLabel.text = [NSString stringWithFormat: @"Reading SAT: %@",  self.school.satScores.reading.stringValue];
    self.satMathCell.textLabel.text = [NSString stringWithFormat: @"Math SAT: %@",  self.school.satScores.math.stringValue];
}

@end

//
//  SchoolDetailViewController.m
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

#import "SchoolDetailViewController.h"
#import "_0190309_AndrewFruth_NYCSchools-Swift.h"

static const int SCHOOL_DETAIL_SECTION_HEADER_HEIGHT = 50;

@interface SchoolDetailViewController() <UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *satWritingCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *satReadingCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *satMathCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *overviewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *phoneCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *websiteCell;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UIButton *phoneButton;
@property (weak, nonatomic) IBOutlet UIButton *websiteButton;

typedef NS_ENUM(NSUInteger, SATTest) {
    SATTestWriting,
    SATTestReading,
    SATTestMath
};

@end

@implementation SchoolDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createSelfSizingLabels];
    
    self.title = self.school.name;
    [self setLabelsText];
    self.tableView.tableFooterView = [[UIView alloc] init];
}
- (IBAction)didClickEmailButton:(UIButton *)sender {
    if (self.school.email) {
        NSString *emailURLString = [NSString stringWithFormat:@"mailto:%@", self.school.email];
        NSURL *emailURL = [[NSURL alloc] initWithString:emailURLString];
        [UIApplication.sharedApplication openURL:emailURL options:@{} completionHandler:nil];
    }
}

- (IBAction)didClickPhoneButton:(UIButton *)sender {
     if (self.school.phone) {
         NSString *phoneURLString = [NSString stringWithFormat:@"tel://%@", self.school.phone];
         NSURL *phoneURL = [[NSURL alloc] initWithString:phoneURLString];
         [UIApplication.sharedApplication openURL:phoneURL options:@{} completionHandler:nil];
     }
}

- (IBAction)didClickWebsite:(UIButton *)sender {
    if (self.school.website) {
        NSURL *websiteURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://%@", self.school.website]];
        [UIApplication.sharedApplication openURL:websiteURL options:@{} completionHandler:nil];
    }
}

- (void)createSelfSizingLabels {
    self.overviewCell.textLabel.numberOfLines = 0;
    self.emailCell.textLabel.numberOfLines = 0;
    self.phoneCell.textLabel.numberOfLines = 0;
    self.websiteCell.textLabel.numberOfLines = 0;
}

- (void)setLabelsText {
    self.satWritingCell.textLabel.text = [self generateTextWithTest:SATTestWriting];
    self.satReadingCell.textLabel.text = [self generateTextWithTest:SATTestReading];
    self.satMathCell.textLabel.text = [self generateTextWithTest:SATTestMath];
    self.overviewCell.textLabel.text = self.school.overview ? self.school.overview : @"No Overview Available";
    
    [self setEmailField];
    [self setPhoneField];
    [self setWebsiteField];
}

// could create a dictionary to map UI elements together to avoid the repetition in the 3 methods below.

- (void)setEmailField {
    if (self.school.email) {
        [self.emailButton setTitle:self.school.email forState:UIControlStateNormal];
    } else {
        self.emailButton.hidden = YES;
        self.emailCell.textLabel.text = @"No Email Available";
    }
}

- (void)setPhoneField {
    if (self.school.phone) {
        [self.phoneButton setTitle:self.school.phone forState:UIControlStateNormal];
    } else {
        self.phoneButton.hidden = YES;
        self.phoneCell.textLabel.text = @"No Phone Available";
    }
}

- (void)setWebsiteField {
    if (self.school.website) {
        [self.websiteButton setTitle:self.school.website forState:UIControlStateNormal];
    } else {
        self.websiteButton.hidden = YES;
        self.websiteCell.textLabel.text = @"No Email Available";
    }
}

- (nullable NSString *)generateTextWithTest:(SATTest)test {
    NSString *noneAvailable = @"None Available";
    SATScores *satScores = self.school.satScores;
    
    switch (test) {
            
        case SATTestWriting:
        {
            NSString *writingScoreText = satScores.writing.stringValue ? satScores.writing.stringValue : noneAvailable;
            return [NSString stringWithFormat: @"Writing: %@",  writingScoreText];
        }
        case SATTestReading:
        {
            NSString *readingScoreText = satScores.reading.stringValue ? satScores.reading.stringValue : noneAvailable;
            return [NSString stringWithFormat: @"Reading: %@",  readingScoreText];
        }
        case SATTestMath:
        {
            NSString *mathScoreText = satScores.math.stringValue ? satScores.math.stringValue : noneAvailable;
            return [NSString stringWithFormat: @"Math: %@",  mathScoreText];
        }
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return SCHOOL_DETAIL_SECTION_HEADER_HEIGHT;
}

@end

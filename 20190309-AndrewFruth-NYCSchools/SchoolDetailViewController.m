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

typedef NS_ENUM(NSUInteger, SATTest) {
    Writing,
    Reading,
    Math
};

@end

@implementation SchoolDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.satWritingCell.textLabel.text = [self generateTextWithTest:Writing];
    self.satReadingCell.textLabel.text = [self generateTextWithTest:Reading];
    self.satMathCell.textLabel.text = [self generateTextWithTest:Math];
}

- (nullable NSString *)generateTextWithTest:(SATTest)test {
    NSString *noneAvailable = @"None Available";

    if (test == Writing) {
        NSString *writingScore = self.school.satScores.writing.stringValue;
        NSString *writingScoreText = writingScore ? writingScore : noneAvailable;
        return [NSString stringWithFormat: @"Writing SAT: %@",  writingScoreText];

    } else if (test == Reading) {
        NSString *readingScore = self.school.satScores.reading.stringValue;
        NSString *readingScoreText = readingScore ? readingScore : noneAvailable;
        return [NSString stringWithFormat: @"Reading SAT: %@",  readingScoreText];

    } else if (test == Math) {
        NSString *mathScore = self.school.satScores.math.stringValue;
        NSString *mathScoreText = mathScore ? mathScore : noneAvailable;
        return [NSString stringWithFormat: @"Math SAT: %@",  mathScoreText];

    }

    return nil;
}

@end

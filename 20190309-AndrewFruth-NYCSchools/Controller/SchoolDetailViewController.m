//
//  SchoolDetailViewController.m
//  20190309-AndrewFruth-NYCSchools
//
//  Created by Andrew Fruth on 3/9/19.
//  Copyright © 2019 Andrew Fruth. All rights reserved.
//

#import "SchoolDetailViewController.h"
#import "_0190309_AndrewFruth_NYCSchools-Swift.h"

@interface SchoolDetailViewController() <UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *satWritingCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *satReadingCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *satMathCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *overviewCell;

typedef NS_ENUM(NSUInteger, SATTest) {
    SATTestWriting,
    SATTestReading,
    SATTestMath
};

@end

@implementation SchoolDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overviewCell.textLabel.numberOfLines = 0;
    
    self.title = self.school.name;
    
    self.satWritingCell.textLabel.text = [self generateTextWithTest:SATTestWriting];
    self.satReadingCell.textLabel.text = [self generateTextWithTest:SATTestReading];
    self.satMathCell.textLabel.text = [self generateTextWithTest:SATTestMath];
    self.overviewCell.textLabel.text = self.school.overview;
}

- (nullable NSString *)generateTextWithTest:(SATTest)test {
    NSString *noneAvailable = @"None Available";

    if (test == SATTestWriting) {
        NSString *writingScore = self.school.satScores.writing.stringValue;
        NSString *writingScoreText = writingScore ? writingScore : noneAvailable;
        return [NSString stringWithFormat: @"Writing: %@",  writingScoreText];

    } else if (test == SATTestReading) {
        NSString *readingScore = self.school.satScores.reading.stringValue;
        NSString *readingScoreText = readingScore ? readingScore : noneAvailable;
        return [NSString stringWithFormat: @"Reading: %@",  readingScoreText];

    } else if (test == SATTestMath) {
        NSString *mathScore = self.school.satScores.math.stringValue;
        NSString *mathScoreText = mathScore ? mathScore : noneAvailable;
        return [NSString stringWithFormat: @"Math: %@",  mathScoreText];

    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}


@end

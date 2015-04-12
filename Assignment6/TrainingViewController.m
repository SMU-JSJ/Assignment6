//
//  TrainingViewController.m
//  Assignment6
//
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "TrainingViewController.h"

@interface TrainingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *spellNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *spellTranslationLabel;
@property (weak, nonatomic) IBOutlet UILabel *spellDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *spellImageView;
@property (weak, nonatomic) IBOutlet UIButton *castSpellButton;

@property (nonatomic) BOOL casting;

@end

@implementation TrainingViewController

- (void)setCasting:(BOOL)casting {
    _casting = casting;
    
    if (casting == YES) {
        [self.castSpellButton setTitle:@"Stop Casting" forState:UIControlStateNormal];
    } else {
        [self.castSpellButton setTitle:@"Start Casting" forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.spellNameLabel.text = self.spellName;
    self.spellTranslationLabel.text = self.spellTranslation;
    self.spellDescriptionLabel.text = self.spellDescription;
    //[self.spellDescriptionLabel sizeToFit];
    self.spellImageView.image = [UIImage imageNamed:self.spellName];
}

- (IBAction)startStopCasting:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"Start Casting"]) {
        self.casting = YES;
    } else {
        self.casting = NO;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

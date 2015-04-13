//
//  TestingViewController.m
//  Assignment6
//
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "TestingViewController.h"
#import "SpellModel.h"

@interface TestingViewController ()

@property (strong, nonatomic) SpellModel* spellModel;

@property (weak, nonatomic) IBOutlet UITableView *spellTableView;

@property (weak, nonatomic) IBOutlet UIButton *castSpellButton;

@property (weak, nonatomic) IBOutlet UIImageView *predictedSpellImageView;
@property (weak, nonatomic) IBOutlet UILabel *predictedSpellNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *yesButton;
@property (weak, nonatomic) IBOutlet UIButton *noButton;

@end

@implementation TestingViewController

// Gets an instance of the SpellModel class using lazy instantiation
- (SpellModel*) spellModel {
    if(!_spellModel)
        _spellModel = [SpellModel sharedInstance];
    
    return _spellModel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return [self.spellModel.attackSpells count];
    } else if (section == 1) {
        return [self.spellModel.healingSpells count];
    } else {
        return [self.spellModel.defenseSpells count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = @"Attack Spells";
            break;
        case 1:
            sectionName = @"Healing Spells";
            break;
        case 2:
            sectionName = @"Defense Spells";
            break;
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SpellTableViewCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Spell* spell;
    if (indexPath.section == 0) {
        spell = self.spellModel.attackSpells[indexPath.row];
    } else if (indexPath.section == 1) {
        spell = self.spellModel.healingSpells[indexPath.row];
    } else {
        spell = self.spellModel.defenseSpells[indexPath.row];
    }
    
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@ 100px", spell.name]];
    cell.textLabel.text = spell.name;
    cell.detailTextLabel.text = spell.translation;
    
    return cell;
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

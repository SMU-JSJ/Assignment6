//
//  TrainingTableViewController.m
//  Assignment6
//
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "TrainingTableViewController.h"
#import "SpellModel.h"
#import "Spell.h"
#import "SpellTableViewCell.h"
#import "TrainingViewController.h"

@interface TrainingTableViewController ()

@property (strong, nonatomic) SpellModel* spellModel;

@end

@implementation TrainingTableViewController

// Gets an instance of the SpellModel class using lazy instantiation
- (SpellModel*) spellModel {
    if(!_spellModel)
        _spellModel = [SpellModel sharedInstance];
    
    return _spellModel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    
    SpellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SpellTableViewCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Spell* spell;
    if (indexPath.section == 0) {
        spell = self.spellModel.attackSpells[indexPath.row];
    } else if (indexPath.section == 1) {
        spell = self.spellModel.healingSpells[indexPath.row];
    } else {
        spell = self.spellModel.defenseSpells[indexPath.row];
    }
    
    cell.spellImageView.image = [UIImage imageNamed:spell.name];
    cell.spellNameLabel.text = spell.name;
    cell.spelLTranslationLabel.text = spell.translation;
    
    return cell;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    BOOL isVC = [[segue destinationViewController] isKindOfClass:[TrainingViewController class]];
    
    if(isVC) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        TrainingViewController *vc = [segue destinationViewController];
        
        Spell* spell;
        if (indexPath.section == 0) {
            spell = self.spellModel.attackSpells[indexPath.row];
        } else if (indexPath.section == 1) {
            spell = self.spellModel.healingSpells[indexPath.row];
        } else {
            spell = self.spellModel.defenseSpells[indexPath.row];
        }
        vc.spellName = spell.name;
        vc.spellTranslation = spell.translation;
        vc.spellDescription = spell.desc;
    }
}

@end

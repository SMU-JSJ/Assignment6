//
//  SpellTableViewCell.h
//  Assignment6
//
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpellTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *spellImageView;
@property (weak, nonatomic) IBOutlet UILabel *spellNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *spelLTranslationLabel;

@end

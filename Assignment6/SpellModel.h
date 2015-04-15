//
//  SpellModel.h
//  Assignment6
//
//  Created by ch484-mac7 on 4/12/15.
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Spell.h"

@interface SpellModel : NSObject

@property (strong, nonatomic) NSMutableArray* attackSpells;
@property (strong, nonatomic) NSMutableArray* healingSpells;
@property (strong, nonatomic) NSMutableArray* defenseSpells;

@property (strong, nonatomic) NSNumber* dsid;

+ (SpellModel*) sharedInstance;

@end

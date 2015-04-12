//
//  SpellModel.m
//  Assignment6
//
//  Created by ch484-mac7 on 4/12/15.
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "SpellModel.h"
#import "Spell.h"

@implementation SpellModel

// Instantiates for the shared instance of the Spell Model class
+ (SpellModel*) sharedInstance {
    static SpellModel* _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[SpellModel alloc] init];
    });
    
    return _sharedInstance;
}

- (NSMutableArray*) attackSpells {
    if(!_attackSpells) {
        _attackSpells = [[NSMutableArray alloc] init];
        
        NSArray* spellNames = @[@"Spell Name 1", @"Spell Name 2", @"Spell Name 3"];
        NSArray* spellTranslations = @[@"Spell Translation 1", @"Spell Translation 2", @"Spell Translation 3"];
        NSArray* spellDescriptions = @[@"Spell Description 1", @"Spell Description 2", @"Spell Description 3"];
        
        for (int i = 0; i < [spellNames count]; i++) {
            Spell* spell = [[Spell alloc] initSpell:spellNames[i]
                                        translation:spellTranslations[i]
                                               desc:spellDescriptions[i]];
            [self.attackSpells addObject:spell];
        }
    }
    
    return _attackSpells;
}

- (NSMutableArray*) healingSpells {
    if(!_healingSpells) {
        _healingSpells = [[NSMutableArray alloc] init];
        
        NSArray* spellNames = @[@"Mentem Curro", @"Spell Name 5", @"Spell Name 6"];
        NSArray* spellTranslations = @[@"Heal Mind", @"Spell Translation 5", @"Spell Translation 6"];
        NSArray* spellDescriptions = @[@"Spell Description 4", @"Spell Description 5", @"Spell Description 6"];
        
        for (int i = 0; i < [spellNames count]; i++) {
            Spell* spell = [[Spell alloc] initSpell:spellNames[i]
                                        translation:spellTranslations[i]
                                               desc:spellDescriptions[i]];
            [self.healingSpells addObject:spell];
        }
    }
    
    return _healingSpells;
}

- (NSMutableArray*) defenseSpells {
    if(!_defenseSpells) {
        _defenseSpells = [[NSMutableArray alloc] init];
        
        NSArray* spellNames = @[@"Spell Name 7", @"Spell Name 8", @"Spell Name 9"];
        NSArray* spellTranslations = @[@"Spell Translation 7", @"Spell Translation 8", @"Spell Translation 9"];
        NSArray* spellDescriptions = @[@"Spell Description 7", @"Spell Description 8", @"Spell Description 9"];
        
        for (int i = 0; i < [spellNames count]; i++) {
            Spell* spell = [[Spell alloc] initSpell:spellNames[i]
                                        translation:spellTranslations[i]
                                               desc:spellDescriptions[i]];
            [self.defenseSpells addObject:spell];
        }
    }
    
    return _defenseSpells;
}


@end

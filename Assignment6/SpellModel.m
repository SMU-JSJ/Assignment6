//
//  SpellModel.m
//  Assignment6
//
//  Created by ch484-mac7 on 4/12/15.
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "SpellModel.h"

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
        
        NSArray* spellNames = @[@"Creo Leonem", @"Percutio Cum Fulmini"];
        NSArray* spellTranslations = @[@"Spell Translation 1", @"Spell Translation 2"];
        NSArray* spellDescriptions = @[@"Spell Description 1", @"Spell Description 2"];
        
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
        
        NSArray* spellNames = @[@"Corpum Sano", @"Magicum Reddo", @"Mentem Curro"];
        NSArray* spellTranslations = @[@"Spell Translation 3", @"Spell Translation 4", @"Heal Mind"];
        NSArray* spellDescriptions = @[@"Spell Description 3", @"Spell Description 4", @"Spell Description 6"];
        
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
        
        NSArray* spellNames = @[@"Arcesso Vallum Terrae", @"Claudo Animum"];
        NSArray* spellTranslations = @[@"Spell Translation 6", @"Spell Translation 7"];
        NSArray* spellDescriptions = @[@"Spell Description 6", @"Spell Description 7"];
        
        for (int i = 0; i < [spellNames count]; i++) {
            Spell* spell = [[Spell alloc] initSpell:spellNames[i]
                                        translation:spellTranslations[i]
                                               desc:spellDescriptions[i]];
            [self.defenseSpells addObject:spell];
        }
    }
    
    return _defenseSpells;
}

- (NSNumber*) dsid {
    if (!_dsid) {
        _dsid = @102;
    }
    
    return _dsid;
}


@end

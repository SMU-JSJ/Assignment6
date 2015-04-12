//
//  Spell.m
//  Assignment6
//
//  Created by ch484-mac7 on 4/12/15.
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "Spell.h"

@implementation Spell

// Constructor
- (id) initSpell:(NSString*) name
     translation:(NSString*) translation
            desc:(NSString*) desc
{
    self = [super init];
    
    // Set member variables
    if (self) {
        self.name = name;
        self.translation = translation;
        self.desc = desc;
    }
    
    return self;
}

@end

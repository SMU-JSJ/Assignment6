//
//  Spell.h
//  Assignment6
//
//  Created by ch484-mac7 on 4/12/15.
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Spell : NSObject

- (id) initSpell:(NSString*) name
     translation:(NSString*) translation
            desc:(NSString*) desc;

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* translation;
@property (strong, nonatomic) NSString* desc;

// add attack/heal/defense points later

@end

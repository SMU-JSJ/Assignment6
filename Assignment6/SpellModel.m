//
//  SpellModel.m
//  Assignment6
//
//  Created by ch484-mac7 on 4/12/15.
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "SpellModel.h"

@interface SpellModel () <NSURLSessionTaskDelegate>

// for the machine learning session
@property (strong,nonatomic) NSURLSession *session;

@end

@implementation SpellModel

@synthesize currentAlgorithm = _currentAlgorithm;

// Instantiates for the shared instance of the Spell Model class
+ (SpellModel*)sharedInstance {
    static SpellModel* _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[SpellModel alloc] init];
    });
    
    return _sharedInstance;
}

- (NSURLSession*)session {
    if (!_session) {
        //setup NSURLSession (ephemeral)
        NSURLSessionConfiguration *sessionConfig =
        [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        sessionConfig.timeoutIntervalForRequest = 5.0;
        sessionConfig.timeoutIntervalForResource = 8.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 1;
        
        _session =
        [NSURLSession sessionWithConfiguration:sessionConfig
                                      delegate:self
                                 delegateQueue:nil];
    }
    return _session;
}

- (NSMutableArray*) attackSpells {
    if(!_attackSpells) {
        _attackSpells = [[NSMutableArray alloc] init];
        
        NSArray* spellNames = @[@"Creo Leonem", @"Percutio Cum Fulmini"];
        NSArray* spellTranslations = @[@"Conjure Lion", @"Lightning Strike"];
        NSArray* spellDescriptions = @[@"Conjures a lion and attacks the opponent.",
                                       @"Strikes a lightning bolt at the opponent."];
        
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
        NSArray* spellTranslations = @[@"Heal Body",
                                       @"Restore Magic",
                                       @"Heal Mind"];
        NSArray* spellDescriptions = @[@"Heals the user's body.",
                                       @"Restores the user's spent magic.",
                                       @"Heals the user's mind."];
        
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
        NSArray* spellTranslations = @[@"Wall of Earth", @"Soul Shield"];
        NSArray* spellDescriptions = @[@"Invokes a wall of earth to block attacks.",
                                       @"Shields the user's soul for opponents."];
        
        for (int i = 0; i < [spellNames count]; i++) {
            Spell* spell = [[Spell alloc] initSpell:spellNames[i]
                                        translation:spellTranslations[i]
                                               desc:spellDescriptions[i]];
            [self.defenseSpells addObject:spell];
        }
    }
    
    return _defenseSpells;
}

- (NSString*)SERVER_URL {
    if (!_SERVER_URL) {
        _SERVER_URL = @"http://jsj.floccul.us:8000";
    }
    return _SERVER_URL;
}

- (NSNumber*)dsid {
    if (!_dsid) {
        _dsid = @102;
    }
    
    return _dsid;
}

- (NSInteger)currentAlgorithm {
    if (!_currentAlgorithm) {
        _currentAlgorithm = 0;
    }
    return _currentAlgorithm;
}

- (void)setCurrentAlgorithm:(NSInteger)currentAlgorithm {
    _currentAlgorithm = currentAlgorithm;
    [self updateModel];
}

- (Spell*) getSpellWithName:(NSString*)spellName {
    for (int i = 0; i < [self.attackSpells count]; i++) {
        Spell* currentSpell = self.attackSpells[i];
        if ([currentSpell.name isEqualToString:spellName]) {
            return currentSpell;
        }
    }
    
    for (int i = 0; i < [self.healingSpells count]; i++) {
        Spell* currentSpell = self.healingSpells[i];
        if ([currentSpell.name isEqualToString:spellName]) {
            return currentSpell;
        }
    }
    
    for (int i = 0; i < [self.defenseSpells count]; i++) {
        Spell* currentSpell = self.defenseSpells[i];
        if ([currentSpell.name isEqualToString:spellName]) {
            return currentSpell;
        }
    }
    
    return nil;
}

- (double) getTotalAccuracy:(NSInteger)algorithm {
    int correctKNN = 0;
    int totalKNN = 0;
    int correctSVM = 0;
    int totalSVM = 0;
    for (int i = 0; i < [self.attackSpells count]; i++) {
        Spell* currentSpell = self.attackSpells[i];
        correctKNN += [currentSpell.correctKNN intValue];
        totalKNN += [currentSpell.totalKNN intValue];
        correctSVM += [currentSpell.correctSVM intValue];
        totalSVM += [currentSpell.totalSVM intValue];
    }
    
    for (int i = 0; i < [self.healingSpells count]; i++) {
        Spell* currentSpell = self.healingSpells[i];
        correctKNN += [currentSpell.correctKNN intValue];
        totalKNN += [currentSpell.totalKNN intValue];
        correctSVM += [currentSpell.correctSVM intValue];
        totalSVM += [currentSpell.totalSVM intValue];
    }
    
    for (int i = 0; i < [self.defenseSpells count]; i++) {
        Spell* currentSpell = self.defenseSpells[i];
        correctKNN += [currentSpell.correctKNN intValue];
        totalKNN += [currentSpell.totalKNN intValue];
        correctSVM += [currentSpell.correctSVM intValue];
        totalSVM += [currentSpell.totalSVM intValue];
    }
    
    if (algorithm == 0) {
        if (totalKNN == 0) {
            return 0;
        }
        return (double)correctKNN/totalKNN * 100;
    } else {
        if (totalSVM == 0) {
            return 0;
        }
        return (double)correctSVM/totalSVM * 100;
    }
}



- (void)updateModel {
    // tell the server to train a new model for the given dataset id (dsid)
    
    // create a GET request and get the reponse back as NSData
    NSString* baseURL;
    if (self.currentAlgorithm == 0) {
        baseURL = [NSString stringWithFormat:@"%@/UpdateModelKNN",self.SERVER_URL];
    } else {
        baseURL = [NSString stringWithFormat:@"%@/UpdateModelSVM",self.SERVER_URL];
    }
    NSString *query = [NSString stringWithFormat:@"?dsid=%d",[self.dsid intValue]];
    
    NSURL *getUrl = [NSURL URLWithString: [baseURL stringByAppendingString:query]];
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:getUrl
                                                 completionHandler:^(NSData *data,
                                                                     NSURLResponse *response,
                                                                     NSError *error) {
                                                     if(!error){
                                                         // we should get back the accuracy of the model
                                                         NSLog(@"%@",response);
                                                         NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &error];
                                                         NSLog(@"Accuracy using resubstitution: %@",responseData[@"resubAccuracy"]);
                                                     }
                                                 }];
    [dataTask resume]; // start the task
}

- (void)sendFeatureArray:(NSArray*)data
               withLabel:(NSString*)label
{
    // Add a data point and a label to the database for the current dataset ID
    
    // setup the url
    NSString *baseURL = [NSString stringWithFormat:@"%@/AddDataPoint",self.SERVER_URL];
    NSURL *postUrl = [NSURL URLWithString:baseURL];
    
    
    // make an array of feature data
    // and place inside a dictionary with the label and dsid
    NSError *error = nil;
    NSDictionary *jsonUpload = @{@"feature":data,
                                 @"label":label,
                                 @"dsid":self.dsid};
    
    NSData *requestBody=[NSJSONSerialization dataWithJSONObject:jsonUpload options:NSJSONWritingPrettyPrinted error:&error];
    
    // create a custom HTTP POST request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postUrl];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestBody];
    
    // start the request, print the responses etc.
    NSURLSessionDataTask *postTask = [self.session dataTaskWithRequest:request
                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                         if(!error){
                                                             NSLog(@"%@",response);
                                                             NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &error];
                                                             
                                                             // we should get back the feature data from the server and the label it parsed
                                                             NSString *featuresResponse = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"feature"]];
                                                             NSString *labelResponse = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"label"]];
                                                             NSLog(@"received %@ and %@",featuresResponse,labelResponse);
                                                             [self updateModel];
                                                         }
                                                     }];
    [postTask resume];
    
}


@end

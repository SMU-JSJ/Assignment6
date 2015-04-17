//  Team JSJ - Jordan Kayse, Jessica Yeh, Story Zanetti
//  TrainingViewController.m
//  Assignment6
//
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "TrainingViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "RingBuffer.h"
#import "SpellModel.h"

#define UPDATE_INTERVAL 1/10.0

@interface TrainingViewController () <NSURLSessionTaskDelegate>

// for the machine learning session
@property (strong,nonatomic) NSURLSession *session;
@property (strong,nonatomic) NSNumber *dsid;

@property (strong, nonatomic) SpellModel* spellModel;

// for storing accelerometer updates
@property (strong, nonatomic) CMMotionManager *cmMotionManager;
@property (strong, nonatomic) NSOperationQueue *backQueue;
@property (strong, nonatomic) RingBuffer *ringBuffer;

@property (weak, nonatomic) IBOutlet UILabel *spellNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *spellTranslationLabel;
@property (weak, nonatomic) IBOutlet UILabel *spellDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *spellImageView;
@property (weak, nonatomic) IBOutlet UIButton *castSpellButton;

@property (strong, nonatomic) NSDate *startCastingTime;
@property (nonatomic) BOOL casting;

@end

@implementation TrainingViewController

// Gets an instance of the SpellModel class using lazy instantiation
- (SpellModel*) spellModel {
    if(!_spellModel)
        _spellModel = [SpellModel sharedInstance];
    
    return _spellModel;
}

// Lazy instantiation

-(CMMotionManager*)cmMotionManager{
    if(!_cmMotionManager){
        _cmMotionManager = [[CMMotionManager alloc] init];
        
        if(![_cmMotionManager isDeviceMotionAvailable])
            _cmMotionManager = nil;
        else
            _cmMotionManager.deviceMotionUpdateInterval = UPDATE_INTERVAL;
    }
    return _cmMotionManager;
}

-(NSOperationQueue*)backQueue{
    
    if(!_backQueue){
        _backQueue = [[NSOperationQueue alloc] init];
    }
    return _backQueue;
}

-(RingBuffer*)ringBuffer{
    if(!_ringBuffer){
        _ringBuffer = [[RingBuffer alloc] init];
    }
    
    return _ringBuffer;
}

// When casting is set, adjust the casting button
// Send gathered data to the database after a user gets a spell
- (void)setCasting:(BOOL)casting {
    _casting = casting;
    
    // If the user is casting, display "Stop Casting" and set the color to red
    // Otherwise, send the gathered data to the database and
    // Display "Start Casting" and set the color to green
    if (casting == YES) {
        self.startCastingTime = [NSDate date];
        [self.ringBuffer reset];

        // Change the casting button
        [self.castSpellButton setTitle:@"Stop Casting" forState:UIControlStateNormal];
        [self.castSpellButton setTitleColor:[[UIColor alloc] initWithRed:255/255.f 
                                                                   green:51/255.f 
                                                                    blue:42/255.f 
                                                                   alpha:1] forState:UIControlStateNormal];
        
        // Disable tab bar buttons
        for (UITabBarItem *tmpTabBarItem in [[self.tabBarController tabBar] items])
            [tmpTabBarItem setEnabled:NO];
    } else {
        // Get the time it took the user to cast the spell
        // And the data from the ring buffer
        double castingTime = fabs([self.startCastingTime timeIntervalSinceNow]);
        NSMutableArray* data = [self.ringBuffer getDataAsVector];

        // Add the casting time to the array of data
        data[0] = [NSNumber numberWithDouble:castingTime];
        
        // Send the feature array to the model
        [self.spellModel sendFeatureArray:data withLabel:self.spell.name];

        // Change the casting button
        [self.castSpellButton setTitle:@"Start Casting" forState:UIControlStateNormal];
        [self.castSpellButton setTitleColor:[[UIColor alloc] initWithRed:67/255.f 
                                                                   green:212/255.f 
                                                                    blue:89/255.f 
                                                                   alpha:1] forState:UIControlStateNormal];
        
        // Enable tab bar buttons
        for (UITabBarItem *tmpTabBarItem in [[self.tabBarController tabBar] items])
            [tmpTabBarItem setEnabled:YES];
    }
}

// Set the information for the current spell when the view loads
// Start adding data to the ring buffer from the motion manager
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // Set the current training spell's name, translation, description, and picture
    self.spellNameLabel.text = self.spell.name;
    self.spellTranslationLabel.text = self.spell.translation;
    self.spellDescriptionLabel.text = self.spell.desc;
    self.spellImageView.image = [UIImage imageNamed:self.spell.name];
    
    self.dsid = self.spellModel.dsid;
        
    // Setup acceleration monitoring
    [self.cmMotionManager startDeviceMotionUpdatesToQueue:self.backQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
        [_ringBuffer addNewData:motion.userAcceleration.x
                          withY:motion.userAcceleration.y
                          withZ:motion.userAcceleration.z];
    }];
}

-(void)dealloc{
    [self.cmMotionManager stopDeviceMotionUpdates];
}

// When the start/stop casting button is clicked, changed the casting state
- (IBAction)startStopCasting:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"Start Casting"]) {
        self.casting = YES;
    } else {
        self.casting = NO;
    }
}

@end

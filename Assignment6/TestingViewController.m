//  Team JSJ - Jordan Kayse, Jessica Yeh, Story Zanetti
//  TestingViewController.m
//  Assignment6
//
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "TestingViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "RingBuffer.h"
#import "SpellModel.h"

#define UPDATE_INTERVAL 1/10.0

@interface TestingViewController () <NSURLSessionTaskDelegate>

// for the machine learning session
@property (strong,nonatomic) NSURLSession* session;
@property (strong,nonatomic) NSNumber* dsid;

@property (strong, nonatomic) SpellModel* spellModel;

// The most recently predicted data and label, to be sent to the server for
// retraining if the user presses "Yes"
@property (strong, nonatomic) NSMutableArray* lastData;
@property (strong, nonatomic) NSString* lastLabel;

// for storing accelerometer updates
@property (strong, nonatomic) CMMotionManager* cmMotionManager;
@property (strong, nonatomic) NSOperationQueue* backQueue;
@property (strong, nonatomic) RingBuffer* ringBuffer;

@property (weak, nonatomic) IBOutlet UIBarButtonItem* algorithmButton;
@property (weak, nonatomic) IBOutlet UITableView* spellTableView;
@property (weak, nonatomic) IBOutlet UIImageView* predictedSpellImageView;

@property (weak, nonatomic) IBOutlet UIButton* castSpellButton;
@property (weak, nonatomic) IBOutlet UIButton* yesButton;
@property (weak, nonatomic) IBOutlet UIButton* noButton;
@property (weak, nonatomic) IBOutlet UILabel* predictedSpellNameLabel;

@property (strong, nonatomic) NSDate* startCastingTime;
@property (nonatomic) BOOL casting;

@end

@implementation TestingViewController

// Gets an instance of the SpellModel class using lazy instantiation
- (SpellModel*)spellModel {
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
// After a user casts a spell, predict what they cast
- (void)setCasting:(BOOL)casting {
    _casting = casting;
    
    // If the user is casting, display "Stop Casting" and set the color to red
    // Otherwise, get the gathered data and predict the spell that was cast
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
        for (UITabBarItem* tmpTabBarItem in [[self.tabBarController tabBar] items])
            [tmpTabBarItem setEnabled:NO];
    } else {
        // Get the time it took the user to cast the spell
        // And the data from the ring buffer
        double castingTime = fabs([self.startCastingTime timeIntervalSinceNow]);
        NSMutableArray* data = [self.ringBuffer getDataAsVector];

        // Add the casting time to the array of data
        data[0] = [NSNumber numberWithDouble:castingTime];

        self.lastData = data;
        
        self.castSpellButton.enabled = NO;

        // Change the button to say "Predicting..."
        [self.castSpellButton setTitle:@"Predicting..." forState:UIControlStateNormal];
        [self.castSpellButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];

        // Predict the spell that the user cast
        [self predictFeature:data];
        
        // Enable tab bar buttons
        for (UITabBarItem* tmpTabBarItem in [[self.tabBarController tabBar] items])
            [tmpTabBarItem setEnabled:YES];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.dsid = self.spellModel.dsid;
    
    // Setup NSURLSession (ephemeral)
    NSURLSessionConfiguration* sessionConfig =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 8.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    
    self.session =
    [NSURLSession sessionWithConfiguration:sessionConfig
                                  delegate:self
                             delegateQueue:nil];
    
    // Setup acceleration monitoring
    [self.cmMotionManager startDeviceMotionUpdatesToQueue:self.backQueue 
                                              withHandler:^(CMDeviceMotion *motion, NSError *error) {
        [_ringBuffer addNewData:motion.userAcceleration.x
                          withY:motion.userAcceleration.y
                          withZ:motion.userAcceleration.z];
    }];
}

// Before the view appears, change the algorithm button to display the correct algorithm
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.spellModel.currentAlgorithm == 0) {
        self.algorithmButton.title = @"KNN";
    } else {
        self.algorithmButton.title = @"SVM";
    }
    [self.spellModel updateModel];
}

-(void)dealloc {
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

// When the yes/no button is clicked, update the model if appropriate
- (IBAction)yesNoClicked:(UIButton*)sender {
    self.castSpellButton.hidden = NO;
    self.castSpellButton.enabled = YES;

    // Change the casting button
    [self.castSpellButton setTitle:@"Start Casting" forState:UIControlStateNormal];
    [self.castSpellButton setTitleColor:[[UIColor alloc] initWithRed:67/255.f 
                                                               green:212/255.f 
                                                                blue:89/255.f 
                                                               alpha:1] forState:UIControlStateNormal];
    
    // Hide views for validating the spell that was cast
    self.predictedSpellImageView.hidden = YES;
    self.predictedSpellNameLabel.hidden = YES;
    self.yesButton.hidden = YES;
    self.noButton.hidden = YES;
    
    // Get the spell predicted from the model
    Spell* currentSpell = [self.spellModel getSpellWithName:self.lastLabel];
    // Increment the total number of guesses for KNN and SVM
    if (currentSpell) {
        if (self.spellModel.currentAlgorithm == 0) {
            currentSpell.totalKNN = [NSNumber numberWithInt:[currentSpell.totalKNN intValue]+1];
        } else {
            currentSpell.totalSVM = [NSNumber numberWithInt:[currentSpell.totalSVM intValue]+1];
        }
    }
    
    // If the model predicted the correct spell
    if ([sender.currentTitle isEqualToString:@"Yes"]) {
        // Send the collected feature data to the model
        [self.spellModel sendFeatureArray:self.lastData withLabel:self.lastLabel];
        
        // Increment the number of correct guesses for KNN and SVM
        if (currentSpell) {
            if (self.spellModel.currentAlgorithm == 0) {
                currentSpell.correctKNN = [NSNumber numberWithInt:[currentSpell.correctKNN intValue]+1];
            } else {
                currentSpell.correctSVM = [NSNumber numberWithInt:[currentSpell.correctSVM intValue]+1];
            }
        }
    }
}

// Change which algorithm is used when the button is clicked
- (IBAction)algorithmButtonClicked:(UIBarButtonItem*)sender {
    if ([sender.title isEqualToString:@"KNN"]) {
        self.spellModel.currentAlgorithm = 1;
        sender.title = @"SVM";
    } else {
        self.spellModel.currentAlgorithm = 0;
        sender.title = @"KNN";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section
    // Each spell type contains a different number
    if (section == 0) {
        return [self.spellModel.attackSpells count];
    } else if (section == 1) {
        return [self.spellModel.healingSpells count];
    } else {
        return [self.spellModel.defenseSpells count];
    }
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    // Change the section name to the appropriate string
    NSString* sectionName;
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

- (UITableViewCell*)tableView:(UITableView*)tableView 
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SpellTableViewCell" 
                                                            forIndexPath:indexPath];
    
    // Configure the cell...
    // Get the proper section and index in the corresponding array of spells
    Spell* spell;
    if (indexPath.section == 0) {
        spell = self.spellModel.attackSpells[indexPath.row];
    } else if (indexPath.section == 1) {
        spell = self.spellModel.healingSpells[indexPath.row];
    } else {
        spell = self.spellModel.defenseSpells[indexPath.row];
    }
    
    // Set the image, name, and translation of the spell in the row
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@ 100px", spell.name]];
    cell.textLabel.text = spell.name;
    cell.detailTextLabel.text = spell.translation;
    
    return cell;
}

// Predict the spell cast by a user
- (void)predictFeature:(NSMutableArray*)featureData {
    // Send the server new feature data and request back a prediction of the class
    
    // Setup the url
    NSString* baseURL;
    // Use the predict function corresponding with the currently selected algorithm
    if (self.spellModel.currentAlgorithm == 0) {
        baseURL = [NSString stringWithFormat:@"%@/PredictOneKNN", self.spellModel.SERVER_URL];
    } else {
        baseURL = [NSString stringWithFormat:@"%@/PredictOneSVM", self.spellModel.SERVER_URL];
    }
    NSURL* postUrl = [NSURL URLWithString:baseURL];
    
    
    // Data to send in body of post request (send arguments as json)
    NSError* error = nil;
    NSDictionary* jsonUpload = @{@"feature":featureData,
                                 @"dsid":self.dsid};
    
    NSData* requestBody=[NSJSONSerialization dataWithJSONObject:jsonUpload 
                                                        options:NSJSONWritingPrettyPrinted 
                                                          error:&error];
    
    // Create a custom HTTP POST request
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:postUrl];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestBody];
    
    // Start the request, print the responses etc.
    NSURLSessionDataTask* postTask = [self.session dataTaskWithRequest:request
        completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
            // If the request completed without error, process the information
            // Otherwise, warn the user of a connectivity error
            if(!error){
              NSDictionary* responseData = [NSJSONSerialization JSONObjectWithData:data 
                                                                        options: NSJSONReadingMutableContainers 
                                                                          error: &error];

              // Create a string of the spell name gotten from the prediction
              NSString* labelResponse = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"prediction"]];
              labelResponse = [[labelResponse substringToIndex:[labelResponse length] - 2] substringFromIndex:3];
              self.lastLabel = labelResponse;

              // Update the UI
              dispatch_async(dispatch_get_main_queue(), ^{
                // If the spell predicted exists, ask the user to confirm
                // Otherwise, display a warning to train more
                if ([self.spellModel getSpellWithName:labelResponse]) {
                  // Hide the casting button
                  self.castSpellButton.hidden = YES;

                  // Show the button/label/images to confirm the prediction with the user
                  self.predictedSpellImageView.hidden = NO;
                  self.predictedSpellNameLabel.hidden = NO;
                  self.yesButton.hidden = NO;
                  self.noButton.hidden = NO;

                  // Update the label and image for the prediction
                  self.predictedSpellNameLabel.text = [NSString stringWithFormat:@"%@?", labelResponse];
                  self.predictedSpellImageView.image = [UIImage imageNamed:labelResponse];
                } else {
                  // Change the casting button
                  [self.castSpellButton setTitle:@"Start Casting" forState:UIControlStateNormal];
                  self.castSpellButton.enabled = YES;
                  [self.castSpellButton setTitleColor:[[UIColor alloc] initWithRed:67/255.f 
                                                                            green:212/255.f 
                                                                             blue:89/255.f 
                                                                            alpha:1] forState:UIControlStateNormal];
                  
                  // Alert the user to train more
                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Spell not found"
                                                                 message:@"Please train more."
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
                  [alert show];
                }
               
              });
            } else {
              // Alert the user of a connection error
              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection error"
                                                             message:@"Please check your Internet connection."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
              [alert show];
            }
         }];
    [postTask resume];
}

@end

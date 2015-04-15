//
//  TestingViewController.m
//  Assignment6
//
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "TestingViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "RingBuffer.h"
#import "SpellModel.h"

#define SERVER_URL "http://jsj.floccul.us:8000"
#define UPDATE_INTERVAL 1/10.0

@interface TestingViewController () <NSURLSessionTaskDelegate>

// for the machine learning session
@property (strong,nonatomic) NSURLSession *session;
@property (strong,nonatomic) NSNumber *dsid;

@property (strong, nonatomic) SpellModel* spellModel;

// The most recently predicted data and label, to be sent to the server for
// retraining if the user presses "Yes"
@property (strong, nonatomic) NSMutableArray* lastData;
@property (strong, nonatomic) NSString* lastLabel;

// for storing accelerometer updates
@property (strong, nonatomic) CMMotionManager *cmMotionManager;
@property (strong, nonatomic) NSOperationQueue *backQueue;
@property (strong, nonatomic) RingBuffer *ringBuffer;

@property (weak, nonatomic) IBOutlet UITableView *spellTableView;

@property (weak, nonatomic) IBOutlet UIButton *castSpellButton;

@property (weak, nonatomic) IBOutlet UIImageView *predictedSpellImageView;
@property (weak, nonatomic) IBOutlet UILabel *predictedSpellNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *yesButton;
@property (weak, nonatomic) IBOutlet UIButton *noButton;

@property (strong, nonatomic) NSDate *startCastingTime;
@property (nonatomic) BOOL casting;

@end

@implementation TestingViewController

// Gets an instance of the SpellModel class using lazy instantiation
- (SpellModel*) spellModel {
    if(!_spellModel)
        _spellModel = [SpellModel sharedInstance];
    
    return _spellModel;
}

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

- (void)setCasting:(BOOL)casting {
    _casting = casting;
    
    if (casting == YES) {
        self.startCastingTime = [NSDate date];
        [self.ringBuffer reset];
        [self.castSpellButton setTitle:@"Stop Casting" forState:UIControlStateNormal];
        [self.castSpellButton setTitleColor:[[UIColor alloc] initWithRed:255/255.f green:51/255.f blue:42/255.f alpha:1] forState:UIControlStateNormal];
    } else {
        double castingTime = fabs([self.startCastingTime timeIntervalSinceNow]);
        NSMutableArray* data = [self.ringBuffer getDataAsVector];
        data[0] = [NSNumber numberWithDouble:castingTime];
        self.lastData = data;
        
        //[self sendFeatureArray:data
        //             withLabel:self.spell.name];
        self.castSpellButton.enabled = NO;
        [self.castSpellButton setTitle:@"Predicting..." forState:UIControlStateNormal];
        [self.castSpellButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self predictFeature:data];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.dsid = self.spellModel.dsid;
    
    //setup NSURLSession (ephemeral)
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 8.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    
    self.session =
    [NSURLSession sessionWithConfiguration:sessionConfig
                                  delegate:self
                             delegateQueue:nil];
    
    // setup acceleration monitoring
    [self.cmMotionManager startDeviceMotionUpdatesToQueue:self.backQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
        [_ringBuffer addNewData:motion.userAcceleration.x
                          withY:motion.userAcceleration.y
                          withZ:motion.userAcceleration.z];
        //NSLog(@"here");
        //float mag = fabs(motion.userAcceleration.x)+fabs(motion.userAcceleration.y)+fabs(motion.userAcceleration.z);
        
        //        if (self.casting){ // do this and return immediately
        //            [self.backQueue addOperationWithBlock:^{
        //                [self motionEventOccurred];
        //            }];
        //        }
    }];

}

-(void)dealloc{
    [self.cmMotionManager stopDeviceMotionUpdates];
}

- (IBAction)startStopCasting:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"Start Casting"]) {
        self.casting = YES;
    } else {
        self.casting = NO;
    }
}

- (IBAction)yesNoClicked:(UIButton *)sender {
    self.castSpellButton.hidden = NO;
    self.castSpellButton.enabled = YES;
    [self.castSpellButton setTitle:@"Start Casting" forState:UIControlStateNormal];
    [self.castSpellButton setTitleColor:[[UIColor alloc] initWithRed:67/255.f green:212/255.f blue:89/255.f alpha:1] forState:UIControlStateNormal];
    self.predictedSpellImageView.hidden = YES;
    self.predictedSpellNameLabel.hidden = YES;
    self.yesButton.hidden = YES;
    self.noButton.hidden = YES;
    
    if ([sender.currentTitle isEqualToString:@"Yes"]) {
        [self sendFeatureArray:self.lastData withLabel:self.lastLabel];
    }
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SpellTableViewCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Spell* spell;
    if (indexPath.section == 0) {
        spell = self.spellModel.attackSpells[indexPath.row];
    } else if (indexPath.section == 1) {
        spell = self.spellModel.healingSpells[indexPath.row];
    } else {
        spell = self.spellModel.defenseSpells[indexPath.row];
    }
    
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@ 100px", spell.name]];
    cell.textLabel.text = spell.name;
    cell.detailTextLabel.text = spell.translation;
    
    return cell;
}

#pragma mark - HTTP Post and Get Request Methods

- (void)updateModel {
    // tell the server to train a new model for the given dataset id (dsid)
    
    // create a GET request and get the reponse back as NSData
    NSString *baseURL = [NSString stringWithFormat:@"%s/UpdateModel",SERVER_URL];
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
    NSString *baseURL = [NSString stringWithFormat:@"%s/AddDataPoint",SERVER_URL];
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

- (void)predictFeature:(NSMutableArray*)featureData {
    // send the server new feature data and request back a prediction of the class
    
    // setup the url
    NSString *baseURL = [NSString stringWithFormat:@"%s/PredictOne",SERVER_URL];
    NSURL *postUrl = [NSURL URLWithString:baseURL];
    
    
    // data to send in body of post request (send arguments as json)
    NSError *error = nil;
    NSDictionary *jsonUpload = @{@"feature":featureData,
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
                                                             NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &error];
                                                             
                                                             NSString *labelResponse = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"prediction"]];
                                                             labelResponse = [[labelResponse substringToIndex:[labelResponse length] - 2] substringFromIndex:3];
                                                             self.lastLabel = labelResponse;
                                                             NSLog(@"%@",labelResponse);
                                                             
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 self.castSpellButton.hidden = YES;
                                                                 self.predictedSpellImageView.hidden = NO;
                                                                 self.predictedSpellNameLabel.hidden = NO;
                                                                 self.yesButton.hidden = NO;
                                                                 self.noButton.hidden = NO;
                                                                 
                                                                 self.predictedSpellNameLabel.text = [NSString stringWithFormat:@"%@?", labelResponse];
                                                                 self.predictedSpellImageView.image = [UIImage imageNamed:labelResponse];
                                                             });
                                                         }
                                                     }];
    [postTask resume];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

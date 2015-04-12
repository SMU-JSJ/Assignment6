//
//  TrainingViewController.m
//  Assignment6
//
//  Copyright (c) 2015 SMUJSJ. All rights reserved.
//

#import "TrainingViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "RingBuffer.h"

#define SERVER_URL "http://Jessicas-MacBook-Air.local:8000"
#define UPDATE_INTERVAL 1/10.0

@interface TrainingViewController () <NSURLSessionTaskDelegate>

// for the machine learning session
@property (strong,nonatomic) NSURLSession *session;
@property (strong,nonatomic) NSNumber *dsid;

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
    } else {
        double castingTime = fabs([self.startCastingTime timeIntervalSinceNow]);
        NSMutableArray* data = [self.ringBuffer getDataAsVector];
        data[0] = [NSNumber numberWithDouble:castingTime];
        
        [self sendFeatureArray:data
                     withLabel:self.spellName];
        [self.castSpellButton setTitle:@"Start Casting" forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.spellNameLabel.text = self.spellName;
    self.spellTranslationLabel.text = self.spellTranslation;
    self.spellDescriptionLabel.text = self.spellDescription;
    //[self.spellDescriptionLabel sizeToFit];
    self.spellImageView.image = [UIImage imageNamed:self.spellName];
    
    self.dsid = @100;
    
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

//-(void)motionEventOccurred{
//    // send data to the server with label
//    [self sendFeatureArray:[self.ringBuffer getDataAsVector]
//                 withLabel:self.spellName];
//}


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

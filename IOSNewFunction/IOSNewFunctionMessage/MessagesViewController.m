//
//  MessagesViewController.m
//  IOSNewFunctionMessage
//
//  Created by 肖扬 on 2016/12/13.
//  Copyright © 2016年 肖扬. All rights reserved.
//

#import "MessagesViewController.h"
#import <HealthKit/HealthKit.h>
#import "WDLineChartView.h"

@interface MessagesViewController ()<WDLineChartViewDataSource, WDLineChartViewDelegate> {
    NSArray *_elementValues;
    NSArray *_elementLables;
    NSArray *_elementDistances;
    NSArray *_elementFlights;
    NSUInteger _numberCount;
    NSUInteger _lastSelected;
    CGFloat _currentMax;
    NSDateFormatter *_formatter;
    NSString *_unit;
    NSUserDefaults *_shared;
    BOOL _errorOccurred;
}
@property (nonatomic, strong) WDLineChartView *lineChartView;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) HKHealthStore *healthStore;
/** 发送按钮 */
@property (nonatomic, strong)  UIButton *sendBtn;

@end

@implementation MessagesViewController

- (void)initWithDate {
    _errorOccurred = NO;
    _numberCount = 7;
    _lastSelected = _numberCount - 1;
    _currentMax = 0;
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setDateFormat:@"M/d"];
    _healthStore = [[HKHealthStore alloc] init];
    _shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.dog.wil.steps"];
    
    NSString *unit = [_shared stringForKey:@"unit"];
    if (unit != nil) {
        _unit = unit;
    } else {
        _unit = @"km";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initWithDate];
    [self addSubMessage];
    [_lineChartView setDataSource:self];
    [_lineChartView setDelegate:self];
    [_lineChartView setShowAverageLine:NO];
    [_lineChartView setBackgroundLineColor:[UIColor clearColor]];
    [self readHealthKitData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadAfterFirstTime) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)addSubMessage
{
    _lineChartView = [[WDLineChartView alloc] initWithFrame:CGRectMake(116, 40, 260, 140)];
    [self.view addSubview:_lineChartView];
    
    _label = [[UILabel alloc] initWithFrame:CGRectMake(16, 40, 110, 100)];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.userInteractionEnabled = YES;
    _label.textColor = [UIColor colorWithWhite:0.3 alpha:1];
    _label.font = [UIFont fontWithName:@"stepfont" size:16.0f];
    _label.numberOfLines = 0;
    [self.view addSubview:_label];
    
    _sendBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    _sendBtn.frame = CGRectMake(16, 155, 100, 30);
    [_sendBtn setTitle:@"发送" forState:(UIControlStateNormal)];
    [_sendBtn setTitleColor:[UIColor orangeColor] forState:(UIControlStateNormal)];
    _sendBtn.layer.cornerRadius = 5;
    _sendBtn.layer.borderColor = [UIColor orangeColor].CGColor;
    _sendBtn.layer.borderWidth = 1.5;
    [_sendBtn addTarget:self action:@selector(sendMessage:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:_sendBtn];
}

- (void)sendMessage:(UIButton *)button
{
    //generate image
    CGFloat xPos = _lineChartView.frame.origin.x + 10;
    CGFloat yPos = _lineChartView.frame.origin.y;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(_lineChartView.frame.size.width + 5, _lineChartView.frame.size.height + 5), NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -xPos, -yPos);
    [self.view.layer.presentationLayer renderInContext:context];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //create msg
    MSMessageTemplateLayout *layout = [[MSMessageTemplateLayout alloc] init];
    layout.image = img;
    NSString *dateString = [@"on " stringByAppendingString:[self labelForElementAtIndex:_lastSelected]];
    if (_lastSelected == _numberCount - 1) {
        dateString = @"今天";
    } else if (_lastSelected == _numberCount - 2) {
        dateString = @"昨天";
    }
    layout.caption = [NSString stringWithFormat:@"我%@步行 %.0f 步, 共%.2f %@",dateString, [self valueForElementAtIndex:_lastSelected],
                      [(NSNumber*)_elementDistances[_lastSelected] doubleValue],
                      _unit];
    MSMessage *msg = [[MSMessage alloc] init];
    msg.layout = layout;
    msg.URL = [NSURL URLWithString:@"emptyURL"];
    
    //send to active conversation
    [self.activeConversation insertMessage:msg completionHandler:^(NSError *error){
        if (error != nil) {
            _label.text = @"创建信息失败";
        }
    }];
    
    //dismiss extension
    [self dismiss];
}

- (void)loadAfterFirstTime {
    [_lineChartView setAnimated:NO];
    [self readHealthKitData];
}

- (void)readHealthKitData
{
    if ([HKHealthStore isHealthDataAvailable]) {
        HKQuantityType *stepType =[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        HKQuantityType *distanceType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
        HKQuantityType *flightsType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
        [_healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:stepType, distanceType, flightsType, nil] completion:^(BOOL success, NSError *error) {
            if (success) {
                [self queryHealthData];
            } else {
                _label.text = @"Health Data Permission Denied";
            }
        }];
    } else {
        _label.text = @"Health Data Not Available";
    }
}

#pragma mark - HealthKit methods
- (void)queryHealthData
{
    NSMutableArray *arrayForValues = [NSMutableArray arrayWithCapacity:_numberCount];
    NSMutableArray *arrayForLabels = [NSMutableArray arrayWithCapacity:_numberCount];
    NSMutableArray *arrayForDistances = [NSMutableArray arrayWithCapacity:_numberCount];
    NSMutableArray *arrayForFlights = [NSMutableArray arrayWithCapacity:_numberCount];
    for (NSUInteger i = 0; i < _numberCount; i++) {
        [arrayForValues addObject:@(0)];
        [arrayForLabels addObject:@""];
        [arrayForDistances addObject:@(0)];
        [arrayForFlights addObject:@(0)];
    }
    _elementValues = (NSArray*)arrayForValues;
    
    dispatch_group_t hkGroup = dispatch_group_create();
    
    HKQuantityType *stepType =[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKQuantityType *distanceType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    HKQuantityType *flightsType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    
    NSDate *day = [NSDate date];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    
    for (NSUInteger i = 0; i < _numberCount; i++) {
        arrayForLabels[_numberCount - 1 - i] = [_formatter stringFromDate:day];
        
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:day];
        components.hour = components.minute = components.second = 0;
        NSDate *beginDate = [calendar dateFromComponents:components];
        NSDate *endDate = day;
        if (i != 0) {
            components.hour = 24;
            components.minute = components.second = 0;
            endDate = [calendar dateFromComponents:components];
        }
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:beginDate endDate:endDate options:HKQueryOptionStrictStartDate];
        
        HKStatisticsQuery *squery = [[HKStatisticsQuery alloc]
                                     initWithQuantityType:stepType
                                     quantitySamplePredicate:predicate
                                     options:HKStatisticsOptionCumulativeSum
                                     completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                                         if (error != nil) _errorOccurred = YES;
                                         HKQuantity *quantity = result.sumQuantity;
                                         double step = [quantity doubleValueForUnit:[HKUnit countUnit]];
                                         [arrayForValues setObject:[NSNumber numberWithDouble:step] atIndexedSubscript:_numberCount - 1 - i];
                                         if (step > _currentMax) _currentMax = step;
                                         dispatch_group_leave(hkGroup);
                                     }];
        HKStatisticsQuery *fquery = [[HKStatisticsQuery alloc]
                                     initWithQuantityType:flightsType
                                     quantitySamplePredicate:predicate
                                     options:HKStatisticsOptionCumulativeSum
                                     completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                                         if (error != nil) _errorOccurred = YES;
                                         HKQuantity *quantity = result.sumQuantity;
                                         double flight = [quantity doubleValueForUnit:[HKUnit countUnit]];
                                         [arrayForFlights setObject:[NSNumber numberWithDouble:flight] atIndexedSubscript:_numberCount - 1 - i];
                                         dispatch_group_leave(hkGroup);
                                     }];
        HKStatisticsQuery *dquery = [[HKStatisticsQuery alloc]
                                     initWithQuantityType:distanceType
                                     quantitySamplePredicate:predicate
                                     options:HKStatisticsOptionCumulativeSum
                                     completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                                         if (error != nil) _errorOccurred = YES;
                                         HKQuantity *quantity = result.sumQuantity;
                                         double distance = [quantity doubleValueForUnit:[HKUnit unitFromString:_unit]];
                                         [arrayForDistances setObject:[NSNumber numberWithDouble:distance] atIndexedSubscript:_numberCount - 1 - i];
                                         dispatch_group_leave(hkGroup);
                                     }];
        dispatch_group_enter(hkGroup);
        [_healthStore executeQuery:squery];
        dispatch_group_enter(hkGroup);
        [_healthStore executeQuery:fquery];
        dispatch_group_enter(hkGroup);
        [_healthStore executeQuery:dquery];
        
        day = [day dateByAddingTimeInterval: -3600 * 24];
    }
    dispatch_group_notify(hkGroup, dispatch_get_main_queue(),^{
        if (!_errorOccurred && _currentMax > 0) {
            _elementValues = (NSArray*)arrayForValues;
            _elementDistances = (NSArray*)arrayForDistances;
            _elementFlights = (NSArray*)arrayForFlights;
            _elementLables = (NSArray*)arrayForLabels;
            [_lineChartView loadDataWithSelectedKept];
            [self changeTextWithNodeAtIndex:_lastSelected];
        } else if (!_errorOccurred && _currentMax <= 0) {
            _label.text = @"No data";
        } else {
            _label.text = @"Some error occured";
        }
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Conversation Handling

-(void)didBecomeActiveWithConversation:(MSConversation *)conversation {
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    
    // Use this method to configure the extension and restore previously stored state.
}

-(void)willResignActiveWithConversation:(MSConversation *)conversation {
    // Called when the extension is about to move from the active to inactive state.
    // This will happen when the user dissmises the extension, changes to a different
    // conversation or quits Messages.
    
    // Use this method to release shared resources, save user data, invalidate timers,
    // and store enough state information to restore your extension to its current state
    // in case it is terminated later.
}

-(void)didReceiveMessage:(MSMessage *)message conversation:(MSConversation *)conversation {
    // Called when a message arrives that was generated by another instance of this
    // extension on a remote device.
    
    // Use this method to trigger UI updates in response to the message.
}

-(void)didStartSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation {
    // Called when the user taps the send button.
}

-(void)didCancelSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation {
    // Called when the user deletes the message without sending it.
    
    // Use this to clean up state related to the deleted message.
}

-(void)willTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle {
    // Called before the extension transitions to a new presentation style.
    
    // Use this method to prepare for the change in presentation style.
}

-(void)didTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle {
    // Called after the extension transitions to a new presentation style.
    
    // Use this method to finalize any behaviors associated with the change in presentation style.
}
#pragma mark - LineChartViewDataSource methods

- (NSUInteger)numberOfElements {
    return _numberCount;
}

- (CGFloat)maxValue {
    return [[_elementValues valueForKeyPath:@"@max.self"] doubleValue];
}

- (CGFloat)minValue {
    return [[_elementValues valueForKeyPath:@"@min.self"] doubleValue];
}

- (CGFloat)averageValue {
    return [[_elementValues valueForKeyPath:@"@avg.self"] doubleValue];
}

- (CGFloat)valueForElementAtIndex:(NSUInteger)index {
    return [(NSNumber*)_elementValues[index] floatValue];
}

- (NSString*)labelForElementAtIndex:(NSUInteger)index {
    return (NSString*)_elementLables[index];
}

#pragma mark - LineChartViewDelegate methods

- (void)clickedNodeAtIndex:(NSUInteger)index {
    [self changeTextWithNodeAtIndex:index];
    _lastSelected = index;
}

- (void)changeTextWithNodeAtIndex:(NSUInteger)index {
    NSString *result = [NSString stringWithFormat:@"\uF3BB  %.0f\n\n\uE801  %.2f %@\n\n\uF148  %.0f F", [(NSNumber*)_elementValues[index] floatValue], [(NSNumber*)_elementDistances[index] floatValue], _unit, [(NSNumber*)_elementFlights[index] floatValue]];
    _label.text = result;
}

@end

//
//  TodayViewController.m
//  IOSNewFunctionWidget
//
//  Created by 肖扬 on 2016/12/13.
//  Copyright © 2016年 肖扬. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "WDLineChartView.h"
#import <HealthKit/HealthKit.h>
#define isIOS10 [[UIDevice currentDevice].systemVersion doubleValue] >= 10.0

@interface TodayViewController () <NCWidgetProviding, WDLineChartViewDelegate, WDLineChartViewDataSource, CAAnimationDelegate> {
    NSArray *_elementValues;
    NSArray *_elementLables;
    NSArray *_elementDistances;
    NSArray *_elementFlights;
    NSUInteger _numberCount;
    CGFloat _currentMax;
    NSDateFormatter *_formatter;
    NSString *_unit;
    NSUserDefaults *_shared;
    BOOL _labelChanged;
    BOOL _errorOccurred;
    BOOL _firstLoaded;
    BOOL _collapsed;
}


@property (nonatomic, strong) WDLineChartView *lineChartView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UILabel *statLabel;
@property (nonatomic, strong) HKHealthStore *healthStore;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initWithDate];
    [self addSubviews];

    self.extensionContext.widgetLargestAvailableDisplayMode = NCWidgetDisplayModeExpanded;
    
    NSString *snapshot = [_shared stringForKey:@"snapshot"];
    NSLog(@"%@", _unit);
    if (snapshot != nil) {
        _label.text = snapshot;
    } else {
        _label.text = [NSString stringWithFormat:@"\uF3BB  ----   \uE801  ---- %@   \uF148  -- F", _unit];
    }
    NSString *stat = [_shared stringForKey:@"stat"];
    if (stat != nil) {
        _statLabel.text = stat;
    } else {
        _statLabel.text = @"每日平均: ---- 步, 一周总共: ----- 步";
    }
    
    [_statLabel.layer setOpacity:0];
    [_lineChartView setBackgroundLineColor:[UIColor colorWithHue:0 saturation:0 brightness:0.75 alpha:0.75]];
    [_lineChartView setAverageLineColor:[UIColor colorWithHue:0 saturation:0 brightness:0.75 alpha:0.75]];
    [_lineChartView setDataSource:self];
    [_lineChartView setDelegate:self];
    [self readHealthKitData];
    
}

- (void)initWithDate
{
    _numberCount = 7;
    _currentMax = 0;
    _labelChanged = NO;
    _errorOccurred = NO;
    _firstLoaded = YES;
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setDateFormat:@"M/d"];
    _healthStore = [[HKHealthStore alloc] init];
    
    _shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.cn.Vickate.IOSNewFunction"];
    
    NSString *unit = [_shared stringForKey:@"unit"];
    NSLog(@"%@", unit);
    if (unit != nil) {
        _unit = unit;
    } else {
        _unit = @"km";
        [_shared setObject:_unit forKey:@"unit"];
        [_shared synchronize];
    }
}


- (void)addSubviews
{
    _lineChartView = [[WDLineChartView alloc] initWithFrame:CGRectMake(0, 100, 375, 150)];
    [self.view addSubview:_lineChartView];
    
    _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 375, 100)];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.userInteractionEnabled = YES;
    _label.textColor = [UIColor colorWithWhite:0.3 alpha:1];
    _label.font = [UIFont fontWithName:@"stepfont" size:22.0f];
    [self.view addSubview:_label];
    
    _statLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 53, 375, 21)];
    _statLabel.textAlignment = NSTextAlignmentCenter;
    _statLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    _statLabel.font = [UIFont systemFontOfSize:13.f];;
    [self.view addSubview:_statLabel];
    
    _errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 19, 335, 81)];
    _errorLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_errorLabel];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [_label addGestureRecognizer:tap];
    
    NSArray *imageArray = @[@"微信", @"QQ", @"微博"];
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap1)];
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap2)];
    UITapGestureRecognizer *tap3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap3)];
    for (int i = 0; i < 3; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(125 * i, 270, 125, 80)];
        imageView.image = [UIImage imageNamed:imageArray[i]];
        [self.view addSubview:imageView];
        imageView.userInteractionEnabled = YES;
        if (i == 0) {
            imageView.frame = CGRectMake(10, 275, 105, 70);
            [imageView addGestureRecognizer:tap1];
        } else if (i == 1) {
            [imageView addGestureRecognizer:tap2];
            imageView.frame = CGRectMake(135, 270, 105, 80);
        } else {
            [imageView addGestureRecognizer:tap3];
        }
    }
}

- (void)tap1
{
    NSURL *url = [NSURL URLWithString:@"weixin://"];
    [self.extensionContext openURL:url completionHandler:^(BOOL success) {
        NSLog(@"isSuccessed %d",success);
    }];
}

- (void)tap2
{
    NSURL *url = [NSURL URLWithString:@"mqq://"];
    [self.extensionContext openURL:url completionHandler:^(BOOL success) {
        NSLog(@"isSuccessed %d",success);
    }];
}

- (void)tap3
{
    NSURL *url = [NSURL URLWithString:@"sinaweibo://"];
    [self.extensionContext openURL:url completionHandler:^(BOOL success) {
        NSLog(@"isSuccessed %d",success);
    }];
}

- (void)tapAction:(UITapGestureRecognizer *)tapGesture
{
    NSLog(@"%s",__func__);
    NSURL *url = [NSURL URLWithString:@"IOSNewFunc://"];
    [self.extensionContext openURL:url completionHandler:^(BOOL success) {
        NSLog(@"isSuccessed %d",success);
    }];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!_labelChanged) {
        if (_collapsed) {
            [_lineChartView removeSublayers];
        } else {
            [_lineChartView setNeedsDisplay];
        }
    }
    _labelChanged = NO;
}



#pragma mark --- 切换展开个折叠回调函数
- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize
{
    NSLog(@"maxWidth %f maxHeight %f",maxSize.width,maxSize.height);
    
    if (activeDisplayMode == NCWidgetDisplayModeExpanded) {
        _collapsed = NO;
        [_lineChartView setHidden:NO];
        self.preferredContentSize = CGSizeMake(0.0, 360.0);
        if (_firstLoaded) {
            _label.layer.transform = CATransform3DMakeTranslation(0, -20, 0);
            [_statLabel.layer setOpacity:1];
        } else {
            [self expandAnimation];
        }
    } else if (activeDisplayMode == NCWidgetDisplayModeCompact) {
        _collapsed = YES;
        [_lineChartView setHidden:YES];
        self.preferredContentSize = maxSize;
        if (!_firstLoaded) [self collapseAnimation];
    }
    _firstLoaded = NO;
}

#pragma mark --- 该方法在iOS10之后被遗弃，iOS10默认不存在间距
//- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets
//{
//    return UIEdgeInsetsMake(0, 10, 0, 10);
//}

#pragma mark --- 应用唤醒
/** 配置url scheme，这个定义的时候尽量不要和其他用用冲突，笔者定义的为WidgetDemo。这样，通过访问WidgetDemo://就可以实现应用唤醒了 */

#pragma mark --- 添加视图
- (void)expandAnimation {
    //today label move up
    CAKeyframeAnimation *moveUpAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CATransform3D transform = CATransform3DMakeTranslation(0, -20, 0);
    [moveUpAnimation setValues:[NSArray arrayWithObjects:
                                [NSValue valueWithCATransform3D:CATransform3DIdentity],
                                [NSValue valueWithCATransform3D:transform],
                                nil]];
    moveUpAnimation.removedOnCompletion = NO;
    moveUpAnimation.fillMode = kCAFillModeForwards;
    moveUpAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.299 : 0.000 : 0.292 : 0.910];
    [moveUpAnimation setDuration: 0.5];
    [_label.layer addAnimation:moveUpAnimation forKey:@"moveUpText"];
    
    //stat label fade in
    CAKeyframeAnimation *fadeInAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    [fadeInAnimation setValues:[NSArray arrayWithObjects:@(0), @(1), nil]];
    fadeInAnimation.removedOnCompletion = NO;
    fadeInAnimation.fillMode = kCAFillModeForwards;
    fadeInAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.354 : 0.000 : 0.223 : 0.841];
    [fadeInAnimation setDuration: 1];
    [_statLabel.layer addAnimation:fadeInAnimation forKey:@"fadeInText"];
}

- (void)collapseAnimation {
    //today label move down
    CAKeyframeAnimation *moveDownAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CATransform3D before = CATransform3DMakeTranslation(0, -20, 0);
    [moveDownAnimation setValues:[NSArray arrayWithObjects:
                                  [NSValue valueWithCATransform3D:before],
                                  [NSValue valueWithCATransform3D:CATransform3DIdentity],
                                  nil]];
    moveDownAnimation.removedOnCompletion = NO;
    moveDownAnimation.fillMode = kCAFillModeForwards;
    moveDownAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.299 : 0.000 : 0.292 : 0.910];
    [moveDownAnimation setDuration: 0.5];
    [[_label layer] addAnimation:moveDownAnimation forKey:@"moveDownText"];
    
    //stat label fade out
    CAKeyframeAnimation *fadeOutAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    [fadeOutAnimation setValues:[NSArray arrayWithObjects:@(1), @(0), nil]];
    fadeOutAnimation.removedOnCompletion = NO;
    fadeOutAnimation.fillMode = kCAFillModeForwards;
    fadeOutAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.000 : 0.076 : 0.104 : 1.000];
    [fadeOutAnimation setDuration: 0.4];
    [_statLabel.layer addAnimation:fadeOutAnimation forKey:@"fadeOutText"];
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
        HKStatisticsQuery *dquery = [[HKStatisticsQuery alloc] initWithQuantityType:distanceType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
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
            [_lineChartView loadData];
            
            NSString *stat = [NSString stringWithFormat:@"每日平均: %.0f 步, 一周总共: %.0f 步", [self averageValue], [self totalValue]];
            _statLabel.text = stat;
            [_shared setObject:stat forKey:@"stat"];
            
            [self changeTextWithNodeAtIndex:_numberCount - 1];
            [_shared setObject:[NSString stringWithFormat:@"\uF3BB  %.0f   \uE801  %.2f %@   \uF148  %.0f F", [(NSNumber*)_elementValues[_numberCount-1] floatValue], [(NSNumber*)_elementDistances[_numberCount-1] floatValue], _unit, [(NSNumber*)_elementFlights[_numberCount-1] floatValue]] forKey:@"snapshot"];
            
            [_shared synchronize];
        } else if (!_errorOccurred && _currentMax <= 0) {
            _errorLabel.text = @"No data";
        } else {
            _errorLabel.text = @"Cannot access full Health data from lock screen";
        }
    });
}

- (void)readHealthKitData
{
    if ([HKHealthStore isHealthDataAvailable]) {
        HKQuantityType *stepType =[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        HKQuantityType *distanceType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
        HKQuantityType *flightsType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
        [_healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:stepType, distanceType, flightsType, nil] completion:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"123");
                [self queryHealthData];
            } else {
                _label.text = @"Health Data Permission Denied";
            }
        }];
    } else {
        _label.text = @"Health Data Not Available";
    }
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

- (CGFloat)valueForElementAtIndex:(NSUInteger)index {
    return [(NSNumber*)_elementValues[index] floatValue];
}

- (CGFloat)averageValue {
    return [[_elementValues valueForKeyPath:@"@avg.self"] doubleValue];
}

- (CGFloat)totalValue {
    return [[_elementValues valueForKeyPath:@"@sum.self"] doubleValue];
}

- (NSString*)labelForElementAtIndex:(NSUInteger)index {
    return (NSString*)_elementLables[index];
}

#pragma mark - LineChartViewDelegate methods

- (void)clickedNodeAtIndex:(NSUInteger)index {
    [self changeTextWithNodeAtIndex:index];
    _labelChanged = YES;
}

- (void)changeTextWithNodeAtIndex:(NSUInteger)index {
    NSString *result = [NSString stringWithFormat:@"\uF3BB  %.0f   \uE801  %.2f %@   \uF148  %.0f F", [(NSNumber*)_elementValues[index] floatValue], [(NSNumber*)_elementDistances[index] floatValue], _unit, [(NSNumber*)_elementFlights[index] floatValue]];
    _label.text = result;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    completionHandler(NCUpdateResultNewData);
}

@end

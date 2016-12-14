//
//  ViewController.m
//  IOSNewFunction
//
//  Created by 肖扬 on 2016/12/13.
//  Copyright © 2016年 肖扬. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>

#import <UserNotifications/UserNotifications.h>

@interface ViewController () <WDLineChartViewDataSource, WDLineChartViewDelegate, UNUserNotificationCenterDelegate> {
    NSArray *_elementValues;
    NSArray *_elementLables;
    NSArray *_elementDistances;
    NSArray *_elementFlights;
    NSUInteger _numberCount;
    NSUInteger _lastSelected;
    NSDateFormatter *_formatter;
    NSString *_unit;
    NSUserDefaults *_shared;
    BOOL _errorOccurred;
    BOOL _firstTimeLoaded;
    BOOL _currentMax;
}

/** content */
@property (nonatomic, strong) UNMutableNotificationContent *content;
/** 点赞 */
@property (nonatomic, strong)  UILabel *zanLabel;
/** 推送 */
@property (nonatomic, strong) UIButton *button;
/** siri */
@property (nonatomic, strong) UIButton *button1;

/** 健康 */
@property (nonatomic, strong)  UILabel *label;
/** statLabel */
@property (nonatomic, strong) UILabel *statLabel;
/** miLabel */
@property (nonatomic, strong) UILabel *miLabel;
/** kmLabel */
@property (nonatomic, strong) UILabel *kmLabel;
/** 表视图 */
@property (nonatomic, strong) WDLineChartView *lineChartView;
@property (nonatomic, strong) HKHealthStore *healthStore;


@end

@implementation ViewController


- (instancetype)initWithCoder:(NSCoder *)aDecoder { // 在 iMessage 和 WidgetVC 里面不可用
    self = [super initWithCoder:aDecoder];
    if (self) {
        _errorOccurred = NO;
        _firstTimeLoaded = YES;
        _numberCount = 7;
        _lastSelected = _numberCount - 1;
        _currentMax = 0;
        _shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.cn.Vickate.IOSNewFunction"];
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"M/d"];
        _healthStore = [[HKHealthStore alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = @"健康";
    [self addSubviews];
    [_lineChartView setDataSource:self];
    [_lineChartView setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDate) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (BOOL)hasCustomNavigationBar {
    return YES;
}

- (void)addSubviews
{
    /** 需创建一个包含待通知内容的 UNMutableNotificationContent 对象，注意不是 UNNotificationContent ,此对象为不可变对象。 */
    _content = [[UNMutableNotificationContent alloc] init];
    
    _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 375, 100)];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.textColor = [UIColor colorWithWhite:0.3 alpha:1];
    UIFont *font = [UIFont fontWithName:@"stepfont" size:22.0f];
    _label.font = font;
    _label.text = @"";
    [self.view addSubview:_label];
    
    _statLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 160, 375, 21)];
    _statLabel.textAlignment = NSTextAlignmentCenter;
    _statLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    _statLabel.font = [UIFont systemFontOfSize:13.f];;
    [self.view addSubview:_statLabel];
    
    _lineChartView = [[WDLineChartView alloc] initWithFrame:CGRectMake(0, 230, kWidth, 150)];
    [self.view addSubview:_lineChartView];
    
    _button = [UIButton buttonWithType:(UIButtonTypeCustom)];
    _button.frame = CGRectMake(300, 490, 60, 60);
    _button.layer.cornerRadius = 30;
    [_button setTitle:@"推送" forState:(UIControlStateNormal)];
    [_button setBackgroundColor:[UIColor orangeColor]];
    [_button addTarget:self action:@selector(btn1) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:_button];
    
    _button1 = [UIButton buttonWithType:(UIButtonTypeCustom)];
    _button1.frame = CGRectMake(300, 560, 60, 60);
    _button1.layer.cornerRadius = 30;
    [_button1 setTitle:@"Siri" forState:(UIControlStateNormal)];
    [_button1 setBackgroundColor:[UIColor purpleColor]];
    [_button1 addTarget:self action:@selector(btn2) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:_button1];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    UIPanGestureRecognizer *pan1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan1:)];
    [_button addGestureRecognizer:pan];
    [_button1 addGestureRecognizer:pan1];
    
}

- (void)pan:(UIPanGestureRecognizer *)gesture
{
    CGPoint translatedPoint = [gesture translationInView:self.view];
    CGFloat x = gesture.view.center.x + translatedPoint.x;
    CGFloat y = gesture.view.center.y + translatedPoint.y;
    gesture.view.center = CGPointMake(x, y);
    [gesture setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (void)pan1:(UIPanGestureRecognizer *)gesture
{
    CGPoint translatedPoint = [gesture translationInView:self.view];
    CGFloat x = gesture.view.center.x + translatedPoint.x;
    CGFloat y = gesture.view.center.y + translatedPoint.y;
    gesture.view.center = CGPointMake(x, y);
    [gesture setTranslation:CGPointMake(0, 0) inView:self.view];
}


- (void)reloadDate {
    if (!_firstTimeLoaded) {
        [_lineChartView setAnimated:NO];
    }
    _firstTimeLoaded = NO;
    [self checkUnitState];
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
                _label.text = @"健康数据请求延时";
            }
        }];
    } else {
        _label.text = @"健康数据不可用";
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
            _statLabel.text = [NSString stringWithFormat:@"每日平均: %.0f 步, 一周总共: %.0f 步", [self averageValue], [self totalValue]];
        } else if (!_errorOccurred && _currentMax <= 0) {
            _label.text = @"没有数据";
        } else {
            _label.text = @"未知错误";
        }
    });
}



- (void)checkUnitState {
    NSString *unit = [_shared stringForKey:@"unit"];
    if (unit != nil) {
        _unit = unit;
        if ([_unit isEqualToString:@"km"]) {
            _kmLabel.textColor = [UIColor colorWithRed:0.3 green:0.85 blue:0.4 alpha:1];
            _miLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
        } else {
            _miLabel.textColor = [UIColor colorWithRed:0.3 green:0.85 blue:0.4 alpha:1];
            _kmLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
        }
    } else {
        _unit = @"km";
        [_shared setObject:_unit forKey:@"unit"];
        [_shared synchronize];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self addLaunchScreenAnimation];
}


- (void)addLaunchScreenAnimation
{
    UIViewController *launchVC = [[UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil] instantiateInitialViewController];
    
    UIView *launchView = launchVC.view;
    
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
    launchView.frame = mainWindow.frame;
    [mainWindow addSubview:launchView];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kWidth, kHeight)];
    imageView.image = [UIImage imageNamed:@"12.jpg"];
    [launchView addSubview:imageView];
    
    [UIView animateWithDuration:1.0f delay:1.9f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        launchView.alpha = 0.0f;
        launchView.layer.transform = CATransform3DScale(CATransform3DIdentity, 2.0f, 2.0f, 1.0f);
    } completion:^(BOOL finished) {
        [launchView removeFromSuperview];
    }];
}


//将图片保存到本地
+ (void)SaveImageToLocal:(UIImage*)image Keys:(NSString*)key {
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    //[preferences persistentDomainForName:LocalPath];
    [preferences setObject:UIImagePNGRepresentation(image) forKey:key];
}

//本地是否有相关图片
+ (BOOL)LocalHaveImage:(NSString*)key {
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    //[preferences persistentDomainForName:LocalPath];
    NSData* imageData = [preferences objectForKey:key];
    if (imageData) {
        return YES;
    }
    return NO;
}

//从本地获取图片
+ (UIImage*)GetImageFromLocal:(NSString*)key {
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    //[preferences persistentDomainForName:LocalPath];
    NSData* imageData = [preferences objectForKey:key];
    UIImage* image;
    if (imageData) {
        image = [UIImage imageWithData:imageData];
    }
    else {
        NSLog(@"未从本地获得图片");
    }
    return image;
}


- (void)btn1
{
    //generate image
//    CGFloat xPos = _lineChartView.frame.origin.x + 10;
//    CGFloat yPos = _lineChartView.frame.origin.y;
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(_lineChartView.frame.size.width + 5, _lineChartView.frame.size.height + 5), NO, 0);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextTranslateCTM(context, -xPos, -yPos);
//    [self.view.layer.presentationLayer renderInContext:context];
//    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    // 当前时间戳
//    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
//    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%.f.jpg", interval]];   // 保存文件的名称
    
#pragma mark - 添加图片
    NSString *imageFile = [[NSBundle mainBundle] pathForResource:@"dots17.1" ofType:@"gif"];
    UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"iamgeAttachment" URL:[NSURL fileURLWithPath:imageFile] options:nil error:nil];
    _content.attachments = @[attachment];
    
    
    [self registNotifitionWithContent:_content];
    
    
#pragma mark - 添加点击操作
    UNTextInputNotificationAction *action = [UNTextInputNotificationAction actionWithIdentifier:@"回复" title:@"回复" options:(UNNotificationActionOptionAuthenticationRequired) textInputButtonTitle:@"回复肖扬" textInputPlaceholder:@"在这里输入回复内容"];
    
    UNNotificationAction *action1 = [UNNotificationAction actionWithIdentifier:@"点赞" title:@"点赞" options:(UNNotificationActionOptionForeground)];
    
    UNNotificationAction *action2 = [UNNotificationAction actionWithIdentifier:@"阅读" title:@"我知道了" options:(UNNotificationActionOptionDestructive)];
    
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"message" actions:@[action, action1, action2] intentIdentifiers:@[] options:(UNNotificationCategoryOptionNone)];
    
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithArray:@[category]]];
    
    _zanLabel.text = @"状态:开始推送";
    
    
}

- (void)btn2
{
    _zanLabel.text = @"状态:对着手机说：“嘿，siri，用新特性发送消息“";
}

- (void)registNotifitionWithContent:(UNMutableNotificationContent *)content
{
    content.title = @"这里是标题";
    content.subtitle = @"这里是副标题";
    content.body = @"这里是常规展示内容ABCDEFG";
    content.categoryIdentifier = @"message";
    /** 在 alertTime 后推送本地推送 */
    /**
     Triggers
     又是一个新的功能，有三种
     UNTimeIntervalNotificationTrigger
     UNCalendarNotificationTrigger
     UNLocationNotificationTrigger
     */
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5.0 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"FiveSecond1" content:content trigger:trigger];
    /** 使用 UNUserNotificationCenter 来管理通知 */
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    /** 添加推送成功后的处理！ */
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (!error) {
            _zanLabel.text = @"开始通知";
        }
    }];
}

/** 收到通知后 */
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler
{
    NSString *categoryIdentifier = response.notification.request.content.categoryIdentifier;
    
    if ([categoryIdentifier isEqualToString:@"message"]) {//识别需要被处理的拓展
        if ([response.actionIdentifier isEqualToString:@"回复"]) {//识别用户点击的是哪个 action
            //假设点击了输入内容的 UNTextInputNotificationAction 把 response 强转类型
            UNTextInputNotificationResponse *textResponse = (UNTextInputNotificationResponse*)response;
            //获取输入内容
            NSString *userText = textResponse.userText;
            NSLog(@"输入内容:%@", userText);
            //发送 userText 给需要接收的方法
            //            [ClassName handleUserText: userText];
        } else if ([response.actionIdentifier isEqualToString:@"点赞"]) {
            NSLog(@"您点击了点赞按钮");
            _zanLabel.text = @"赞：1";
        }else {
            
        }
    }
    completionHandler();
}

#pragma mark - LineChartViewDelegate methods

- (void)clickedNodeAtIndex:(NSUInteger)index {
    [self changeTextWithNodeAtIndex:index];
    _lastSelected = index;
}

- (void)changeTextWithNodeAtIndex:(NSUInteger)index {
    
    NSString *result = [NSString stringWithFormat:@"\uF3BB  %.0f   \uE801  %.2f %@   \uF148  %.0f F", [(NSNumber*)_elementValues[index] floatValue], [(NSNumber*)_elementDistances[index] floatValue], _unit, [(NSNumber*)_elementFlights[index] floatValue]];
    _label.text = result;
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

- (CGFloat)totalValue {
    return [[_elementValues valueForKeyPath:@"@sum.self"] doubleValue];
}

- (CGFloat)valueForElementAtIndex:(NSUInteger)index {
    return [(NSNumber*)_elementValues[index] floatValue];
}

- (NSString*)labelForElementAtIndex:(NSUInteger)index {
    return (NSString*)_elementLables[index];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

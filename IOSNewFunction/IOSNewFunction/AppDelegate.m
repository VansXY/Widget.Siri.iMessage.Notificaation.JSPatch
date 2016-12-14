//
//  AppDelegate.m
//  IOSNewFunction
//
//  Created by 肖扬 on 2016/12/13.
//  Copyright © 2016年 肖扬. All rights reserved.
//

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate ()<UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self startJSP];
    [self registNotification];
    [self createShortcutItems];
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark --- 开启 JSPatch
- (void)startJSP
{
    //    [JPEngine startEngine];
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"JSPDemo" ofType:@"js"];
    NSString *scripe = [NSString stringWithContentsOfFile:sourcePath encoding:(NSUTF8StringEncoding) error:nil];
    [JPEngine evaluateScript:scripe];
}

#pragma mark --- 注册本地通知
- (void)registNotification
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"request authorization succeeded!");
        } else {
            NSLog(@"request authorization fail!");
        }
    }];
    
    /** 打印通知消息 */
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        NSLog(@"%@",settings);
    }];
}

#pragma mark --- 创建3DTouch操作
- (void)createShortcutItems
{
    NSUserDefaults *share = [[NSUserDefaults standardUserDefaults] initWithSuiteName:@"group.cn.Vickate.IOSNewFunction"];
    
    // 初始化 icon
    UIApplicationShortcutIcon *kmIcon = nil;
    UIApplicationShortcutIcon *miIcon = nil;
    if ([[share valueForKey:@"unit"] isEqualToString:@"mi"]) {
        miIcon = [UIApplicationShortcutIcon iconWithType:(UIApplicationShortcutIconTypeTaskCompleted)];
        
        kmIcon = [UIApplicationShortcutIcon iconWithType:(UIApplicationShortcutIconTypeTask)];
    } else {
        miIcon = [UIApplicationShortcutIcon iconWithType:(UIApplicationShortcutIconTypeTask)];
        kmIcon = [UIApplicationShortcutIcon iconWithType:(UIApplicationShortcutIconTypeTaskCompleted)];
    }
    // 初始化 item
    UIApplicationShortcutItem *kmItem = [[UIApplicationShortcutItem alloc] initWithType:@"cn.Vickate.IOSNewFunction.set-unit-to-km" localizedTitle:@"set-unit-to-km" localizedSubtitle:nil icon:kmIcon userInfo:nil];
    
    UIApplicationShortcutItem *miItem = [[UIApplicationShortcutItem alloc] initWithType:@"cn.Vickate.IOSNewFunction.set-unit-to-mi" localizedTitle:@"set-unit-to-mi" localizedSubtitle:nil icon:miIcon userInfo:nil];
    
    NSArray *items = @[kmItem, miItem];
    
    [UIApplication sharedApplication].shortcutItems = items;
}

#pragma mark --- 点击3DTouch后的回调方法
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    NSUserDefaults *share =[[NSUserDefaults alloc] initWithSuiteName:@"group.cn.Vickate.IOSNewFunction"];
    if ([shortcutItem.type isEqual:@"cn.Vickate.IOSNewFunction.set-unit-to-km"]) {
        [share setObject:@"km" forKey:@"unit"];
    } else if ([shortcutItem.type isEqual:@"cn.Vickate.IOSNewFunction.set-unit-to-mi"]) {
        [share setObject:@"mi" forKey:@"unit"];
    }
    [share synchronize];
    [self createShortcutItems];
}


/** 回调 widget 的点击方法 */
//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
//{
//    if ([[url absoluteString] hasPrefix:@"WidgetDemo"])
//    {
//        NSLog(@"nidianjile");
//    }
//    return  YES;
//}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end

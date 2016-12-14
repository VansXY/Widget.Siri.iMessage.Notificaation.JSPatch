//
//  AppDelegate.h
//  IOSNewFunction
//
//  Created by 肖扬 on 2016/12/13.
//  Copyright © 2016年 肖扬. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/** 添加3DTouch 效果 */
- (void)createShortcutItems;

@end


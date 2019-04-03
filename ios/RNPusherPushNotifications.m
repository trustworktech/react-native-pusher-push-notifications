#import "RNPusherEventHelper.h"
#import "RNPusherPushNotifications.h"
#import <UIKit/UIKit.h>
#import "RCTLog.h"
@import PushNotifications;

/// From:
/// https://github.com/pusher/push-notifications-swift/blob/master/Sources/Constants.swift
#define PUSHER_SUITE_NAME @"PushNotifications"
#define PUSHER_DEVICE_ID @"com.pusher.sdk.deviceId"

@implementation RNPusherPushNotifications

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue {
  return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(setInstanceId : (NSString *)instanceId) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTLogInfo(@"Creating pusher with Instance ID: %@", instanceId);
    
    [[PushNotifications shared] startWithInstanceId:instanceId];
    [[PushNotifications shared] registerForRemoteNotifications];
  });
}

RCT_EXPORT_METHOD(subscribe
                  : (NSString *)interest callback
                  : (RCTResponseSenderBlock)callback) {
  RCTLogInfo(@"Subscribing to interest: %@", interest);
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *anyError;
    [[PushNotifications shared]
     subscribeWithInterest:interest
     error:&anyError
     completion:^{
       if (anyError) {
         callback(@[ anyError, [NSNull null] ]);
       } else {
         RCTLogInfo(@"Subscribed to interest: %@", interest);
       }
     }];
  });
}

RCT_EXPORT_METHOD(setSubscriptions
                  : (NSArray *)interests callback
                  : (RCTResponseSenderBlock)callback) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *anyError;
    [[PushNotifications shared]
     setSubscriptionsWithInterests:interests
     error:&anyError
     completion:^{
       if (anyError) {
         callback(@[ anyError, [NSNull null] ]);
       } else {
         RCTLogInfo(@"Subscribed to interests: %@",
                    interests);
       }
     }];
  });
}

RCT_EXPORT_METHOD(unsubscribe
                  : (NSString *)interest callback
                  : (RCTResponseSenderBlock)callback) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *anyError;
    [[PushNotifications shared]
     unsubscribeWithInterest:interest
     error:&anyError
     completion:^{
       if (anyError) {
         callback(@[ anyError, [NSNull null] ]);
       } else {
         RCTLogInfo(@"Unsubscribed from interest: %@",
                    interest);
       }
     }];
  });
}

+ (BOOL)deviceIdAlreadyPresent {
  return nil != [[[NSUserDefaults alloc] initWithSuiteName:PUSHER_SUITE_NAME]
                 stringForKey:PUSHER_DEVICE_ID];
}

+ (void)handleNotification:(NSDictionary *)userInfo {
  UIApplicationState state = [UIApplication sharedApplication].applicationState;
  
  NSString *appState = @"active";
  RCTLogInfo(@"handleNotification: %@", userInfo);
  
  if (state == UIApplicationStateActive) {
    RCTLogInfo(
               @"1. App is foreground and notification is recieved. Show a alert.");
  } else if (state == UIApplicationStateBackground) {
    RCTLogInfo(@"2. App is in background and notification is received. You can "
               @"fetch required data here don't do anything with UI.");
    appState = @"background";
  } else if (state == UIApplicationStateInactive) {
    RCTLogInfo(@"3. App came in foreground by used clicking on notification. "
               @"Use userinfo for redirecting to specific view controller.");
    appState = @"inactive";
  }
  
  [RNPusherEventHelper emitEventWithName:@"notification"
                              andPayload:@{
                                           @"userInfo" : userInfo,
                                           @"appState" : appState
                                           }];
  
  [[PushNotifications shared] handleNotificationWithUserInfo:userInfo];
}

+ (void)setDeviceToken:(NSData *)deviceToken {
  RCTLogInfo(@"setDeviceToken: %@", deviceToken);
  
  if ([RNPusherPushNotifications deviceIdAlreadyPresent]) {
    [RNPusherEventHelper emitEventWithName:@"registered" andPayload:@{}];
    return;
  }
  
  [[PushNotifications shared] registerDeviceToken:deviceToken
                                       completion:^{
                                         [RNPusherEventHelper
                                          emitEventWithName:@"registered"
                                          andPayload:@{}];
                                         RCTLogInfo(@"REGISTERED!");
                                       }];
}

@end

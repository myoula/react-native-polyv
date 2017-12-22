//
//  RCTLiveManager.m
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/25.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import <React/RCTBridge.h>
#import "RCTLiveManager.h"
#import "RCTLive.h"

@implementation RCTLiveManager

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (UIView *)view
{
    return [[RCTLive alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

RCT_EXPORT_VIEW_PROPERTY(message, NSString);

RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(onLoaded, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onPlaying, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onStop, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onReceiveMessage, RCTDirectEventBlock);

@end


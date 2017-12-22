//
//  RCTPlayerManager.m
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/23.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import "RCTPlayerManager.h"
#import "RCTPlayer.h"
#import <React/RCTBridge.h>

@implementation RCTPlayerManager

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (UIView *)view
{
    return [[RCTPlayer alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(paused, BOOL);
RCT_EXPORT_VIEW_PROPERTY(seek, float);

RCT_EXPORT_VIEW_PROPERTY(onLoading, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onLoaded, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onPlaying, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onPaused, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onStop, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock);

@end

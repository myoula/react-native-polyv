//
//  RCTPlayer.h
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/23.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <React/RCTView.h>
#import <React/RCTLog.h>

#import <AlicloudUtils/AlicloudReachabilityManager.h>
#import "PLVMoviePlayerController.h"

@class RCTEventDispatcher;

@interface RCTPlayer : UIView
- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;

@property (nonatomic) BOOL paused;
@property (nonatomic) float seek;

@property (nonatomic, copy) RCTDirectEventBlock onLoading;
@property (nonatomic, copy) RCTDirectEventBlock onLoaded;
@property (nonatomic, copy) RCTDirectEventBlock onPlaying;
@property (nonatomic, copy) RCTDirectEventBlock onPaused;
@property (nonatomic, copy) RCTDirectEventBlock onStop;
@property (nonatomic, copy) RCTDirectEventBlock onError;
@end

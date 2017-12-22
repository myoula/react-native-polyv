//
//  RCTLive.h
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/25.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <React/RCTView.h>
#import <React/RCTLog.h>
#import <IJKMediaFramework/IJKMediaFramework.h>
#import <PLVLiveAPI/PLVLiveAPI.h>
#import <PLVLiveAPI/PLVSettings.h>
#import <PLVChatManager/PLVChatManager.h>

@class RCTEventDispatcher;

@interface RCTLive : UIView<SocketIODelegate>

@property (nonatomic, strong) PLVChannel *channel;
@property (nonatomic, strong) IJKFFMoviePlayerController *player;

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) RCTDirectEventBlock onLoaded;
@property (nonatomic, copy) RCTDirectEventBlock onPlaying;
@property (nonatomic, copy) RCTDirectEventBlock onStop;
@property (nonatomic, copy) RCTDirectEventBlock onError;

@property (nonatomic, copy) RCTDirectEventBlock onReceiveMessage;
@end

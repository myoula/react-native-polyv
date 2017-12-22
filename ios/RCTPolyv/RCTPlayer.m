//
//  RCTPlayer.m
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/23.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import "RCTPlayer.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>

@implementation RCTPlayer
{
    RCTEventDispatcher *_eventDispatcher;
    PLVMoviePlayerController *player;
    NSTimer *playbackTimer;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if ((self = [super init])) {
        _eventDispatcher = eventDispatcher;
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    
    return self;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    
    if (!_paused) {
        [self setPaused:_paused];
    }
}


- (void)applicationWillEnterForeground:(NSNotification *)notification {
    
    if(!_paused) {
        [self setPaused:NO];
    }
}

- (void) setSource:(NSDictionary *)source
{
    NSString *vid = source[@"vid"];
    player = [[PLVMoviePlayerController alloc] initWithVid:vid];
    
    [self setupUI];
    [self configObserver];
}

- (void)setPaused:(BOOL)paused {
    if (player) {
        if (paused) {
            [player pause];
        } else {
            [player play];
        }
        _paused = paused;
    }
}

- (void)setSeek:(float)seek {
    
    [player pause];
    [player setCurrentPlaybackTime:seek];
    [player play];
}

- (void)setupUI {
    
    UIView *playerView = player.view;
    [self addSubview: playerView];
    [playerView setTranslatesAutoresizingMaskIntoConstraints:NO];

    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
    
    NSArray *constraints = [NSArray arrayWithObjects:centerX, centerY,width,height, nil];
    [self addConstraints: constraints];
    
    [player play];
    
}

- (void)configObserver; {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    // 播放状态改变，可配合playbakcState属性获取具体状态
    [notificationCenter addObserver:self selector:@selector(onMPMoviePlayerPlaybackStateDidChangeNotification)
                               name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    // 媒体网络加载状态改变
    [notificationCenter addObserver:self selector:@selector(onMPMoviePlayerLoadStateDidChangeNotification)
                               name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    
    // 播放时长可用
    [notificationCenter addObserver:self selector:@selector(onMPMovieDurationAvailableNotification)
                               name:MPMovieDurationAvailableNotification object:nil];
    // 媒体播放完成或用户手动退出, 具体原因通过MPMoviePlayerPlaybackDidFinishReasonUserInfoKey key值确定
    [notificationCenter addObserver:self selector:@selector(onMPMoviePlayerPlaybackDidFinishNotification:)
                               name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    // 视频就绪状态改变
    [notificationCenter addObserver:self selector:@selector(onMediaPlaybackIsPreparedToPlayDidChangeNotification)
                               name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:nil];
    
    // 播放资源变化
    [notificationCenter addObserver:self selector:@selector(onMPMoviePlayerNowPlayingMovieDidChangeNotification)
                               name:MPMoviePlayerNowPlayingMovieDidChangeNotification object:nil];
}

#pragma Movie Player delegate

// 播放状态改变
- (void)onMPMoviePlayerPlaybackStateDidChangeNotification {
    
    
    if (player.playbackState == MPMoviePlaybackStatePlaying) {
        if (self.onPlaying) {
            self.onPlaying(@{ @"target": self.reactTag,
                              @"current" : [NSNumber numberWithDouble:player.currentPlaybackTime],
                              @"duration": [NSNumber numberWithDouble:player.duration]});
        }
        _paused = NO;
        [self startPlaybackTimer];
    } else if (player.playbackState == MPMoviePlaybackStatePaused) {
        RCTLogInfo(@"pause");
        if (self.onPaused) {
            self.onPaused(@{ @"target": self.reactTag});
        }
        _paused = YES;
        [self releaseTimer];
    } else if (player.playbackState == MPMoviePlaybackStateStopped) {
        
    } else {
        RCTLogInfo(@"unkown");
    }
}

// 网络加载状态改变
- (void)onMPMoviePlayerLoadStateDidChangeNotification {
    
    if (player.loadState & MPMovieLoadStateStalled) {
        if (self.onLoading) {
            self.onLoading(@{ @"target": self.reactTag});
        }
        
    } else if (player.loadState & MPMovieLoadStatePlaythroughOK) {
        RCTLogInfo(@"can play");
    } else if (player.loadState & MPMovieLoadStatePlayable) {
        RCTLogInfo(@"playable");
    } else {
        if (self.onError) {
            self.onError(@{ @"target": self.reactTag});
        }
    }
}

// 成功获取视频时长
- (void)onMPMovieDurationAvailableNotification {
    
    if (self.onLoaded) {
        self.onLoaded(@{ @"target": self.reactTag,
                         @"duration": [NSNumber numberWithDouble:player.duration]});
    }
}

// 播放完成或退出
- (void)onMPMoviePlayerPlaybackDidFinishNotification:(NSNotification *)notification {
    MPMovieFinishReason finishReason = [notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
    RCTLogInfo(@"stop");
    [self releaseTimer];
    
    if (self.onStop) {
        self.onStop(@{ @"target": self.reactTag});
    }
}

// 做好播放准备后
- (void)onMediaPlaybackIsPreparedToPlayDidChangeNotification {
    RCTLogInfo(@"prepare");
}

// 播放资源变化
- (void)onMPMoviePlayerNowPlayingMovieDidChangeNotification {
    RCTLogInfo(@"change");
}

- (void)startPlaybackTimer {
    if (!playbackTimer) {
        playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(monitorVideoPlayback) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:playbackTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)monitorVideoPlayback {
    if (self.onPlaying) {
        self.onPlaying(@{ @"target": self.reactTag,
                          @"current" : [NSNumber numberWithDouble:player.currentPlaybackTime],
                          @"duration": [NSNumber numberWithDouble:player.duration]});
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    if(!newWindow) {
        [self releasePlayer];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if(!newSuperview) {
        [self releasePlayer];
    }
}

- (void)releaseTimer {
    if (playbackTimer) {
        [playbackTimer invalidate];
        playbackTimer = nil;
    }
}

- (void)releasePlayer {
    if(player) {
        [self releaseTimer];
        [player pause];
        player = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

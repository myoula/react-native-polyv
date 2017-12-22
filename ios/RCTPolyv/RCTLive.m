//
//  RCTLive.m
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/25.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import "RCTLive.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>

NSString * const LivePlayerReconnectNotification = @"LivePlayerReconnectNotification";

@implementation RCTLive
{
    RCTEventDispatcher *_eventDispatcher;
    PLVChatSocket *chatSocket;
    NSTimer *liveStatusTimer;
    NSTimer *playerPollingTimer;
    int _watchTimeDuration;
    int _stayTimeDuration;
    NSInteger _reportFreq;
    NSString *_pid;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if ((self = [super init])) {
        _eventDispatcher = eventDispatcher;
    }
    
    return self;
}

- (void) setSource:(NSDictionary *)source
{
    NSString *channel = source[@"channel"];
    
    RCTLogInfo(@"config");
    
    [PLVChannel loadVideoJsonWithUserId:@"c9dfafc016" channelId:@"141092" completionHandler:^(PLVChannel *channel) {
        
        self.channel = channel;
        _reportFreq = channel.reportFreq.integerValue;
        NSURL *aUrl = [NSURL URLWithString:channel.flvUrl];
        
        IJKFFOptions *options = [IJKFFOptions optionsByDefault];
        [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"];
        [options setFormatOptionValue:@"500000" forKey:@"analyzeduration"];
        [options setFormatOptionValue:@"4096" forKey:@"probesize"];
        
        self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:aUrl withOptions:options];
        _pid = [PLVReportManager getPid];
        
        [self setupUI];
        [self configChatSocket];
        [self configObservers];
        [self addTimerEvents];
        
    } failureHandler:^(NSString *errorName, NSString *errorDescription) {
        if (self.onError) {
            self.onError(@{ @"target": self.reactTag});
        }
    }];
}

- (void) setMessage:(NSString *)message
{
    [chatSocket sendMessageWithContent:message];
}

- (void)setupUI {
    
    UIView *playerView = self.player.view;
    [self addSubview: playerView];
    [playerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
    
    NSArray *constraints = [NSArray arrayWithObjects:centerX, centerY,width,height, nil];
    [self addConstraints: constraints];
    
    [self.player setShouldAutoplay:YES];
    [self.player setScalingMode:IJKMPMovieScalingModeAspectFit];
    [self.player prepareToPlay];
    [self.player play];
    
}

- (void)configChatSocket {
    [PLVChatRequest getChatTokenWithAppid:[PLVSettings sharedInstance].getAppId appSecret:[PLVSettings sharedInstance].getAppSecret success:^(NSString *chatToken) {
        RCTLogInfo(@"chat init");
        
        @try {
            // 初始化聊天室
            chatSocket = [[PLVChatSocket alloc] initChatSocketWithConnectToken:chatToken enableLog:NO];
            chatSocket.delegate = self;    // 设置代理
            [chatSocket connect];          // 连接聊天室
        } @catch (NSException *exception) {
            
        }
        
    } failure:^(NSString *errorName, NSString *errorDescription) {
        RCTLogInfo(@"chat error");
    }];
}

- (void)configObservers {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerReconnectNotification) name:LivePlayerReconnectNotification object:nil];
    
    [defaultCenter addObserver:self selector:@selector(movieNaturalSizeAvailable:) name:IJKMPMovieNaturalSizeAvailableNotification object:nil];
    
    [defaultCenter addObserver:self selector:@selector(mediaPlaybackIsPreparedToPlay:) name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:nil];
    
    [defaultCenter addObserver:self selector:@selector(moviePlayerLoadStateDidChange:) name:IJKMPMoviePlayerLoadStateDidChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(moviePlayerPlaybackStateDidChange:) name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(moviePlayerPlaybackDidFinish:) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)addTimerEvents {
    liveStatusTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self
                                                     selector:@selector(onTimeCheckLiveStreamState) userInfo:nil repeats:YES];
    
    playerPollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                         selector:@selector(playerPollingTimerTick) userInfo:nil repeats:YES];
    
    [liveStatusTimer fire];
}

- (void)onTimeCheckLiveStreamState {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 异步线程中请求（该方法为同步线程）
        NSInteger streamState = [PLVChannel isLiveWithStreame:self.channel.stream];
        
        // 回主线程更新
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (streamState) {
                case PLVLiveStreamStateNoStream: {
                    //直播未在进行
                    if (self.onStop) {
                        self.onStop(@{ @"target": self.reactTag});
                    }
                    
                    [self.player shutdown];
                }
                    break;
                case PLVLiveStreamStateLive: {
                    //直播中
                    if (self.onPlaying) {
                        self.onPlaying(@{ @"target": self.reactTag});
                    }
                    if (self.player.playbackState == IJKMPMoviePlaybackStateStopped) {
                        //发送播放器重连通知
                        [[NSNotificationCenter defaultCenter] postNotificationName:LivePlayerReconnectNotification object:nil];
                    }
                }
                    break;
                case PLVLiveStreamStateUnknown:
                    //直播状态未知
                    if (self.onError) {
                        self.onError(@{ @"target": self.reactTag});
                    }
                    break;
                default:
                    break;
            }
        });
    });
}

- (void)playerPollingTimerTick {
    ++ _stayTimeDuration;
    if (self.player.playbackState & IJKMPMoviePlaybackStatePlaying) {
        ++ _watchTimeDuration;
        if ( _watchTimeDuration%_reportFreq == 0) {
            [PLVReportManager stat:_pid uid:self.channel.userId cid:self.channel.channelId flow:0 pd:_watchTimeDuration sd:_stayTimeDuration cts:[self.player currentPlaybackTime] duration:[self.player duration]];
        }
    }
}

- (void)livePlayerReconnectNotification {
    __weak typeof(self)weakSelf = self;
    [PLVChannel loadVideoJsonWithUserId:self.channel.userId channelId:self.channel.channelId completionHandler:^(PLVChannel *channel) {
        weakSelf.channel = channel;
        
        [weakSelf releasePlayer];
        
        NSURL *aUrl = [NSURL URLWithString:channel.flvUrl];
        
        IJKFFOptions *options = [IJKFFOptions optionsByDefault];
        [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"];
        [options setFormatOptionValue:@"500000" forKey:@"analyzeduration"];
        [options setFormatOptionValue:@"4096" forKey:@"probesize"];
        weakSelf.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:aUrl withOptions:options];
        
        [weakSelf setupUI];
        [weakSelf addTimerEvents];
        [weakSelf configObservers];
        
    } failureHandler:^(NSString *errorName, NSString *errorDescription) {
        if (self.onError) {
            self.onError(@{ @"target": self.reactTag});
        }
    }];
}

- (void)socketIODidConnect:(PLVChatSocket *)chatSocket {
    RCTLogInfo(@"chat connect");
    
    [chatSocket loginChatRoomWithChannelId:self.channel.channelId nickName:@"fuck" avatar:@"http://www.polyv.net/images/effect/effect-device.png"];
}

/** socket收到聊天室信息*/
- (void)socketIODidReceiveMessage:(PLVChatSocket *)chatSocket withChatObject:(PLVChatObject *)chatObject {
    RCTLogInfo(@"chat info");
    
    NSString* messageType = @"PLVChatMessageTypeCloseRoom";
    switch (chatObject.messageType) {
        case PLVChatMessageTypeCloseRoom: {
            messageType = @"PLVChatMessageTypeCloseRoom";
        }
            break;
        case PLVChatMessageTypeOpenRoom: {
            messageType = @"PLVChatMessageTypeOpenRoom";
        }
            break;
        case PLVChatMessageTypeGongGao: {
            messageType = @"PLVChatMessageTypeGongGao";
        }
            break;
        case PLVChatMessageTypeSpeak: {
            messageType = @"PLVChatMessageTypeSpeak";
        }
            break;
        case PLVChatMessageTypeOwnWords: {
            messageType = @"PLVChatMessageTypeOwnWords";
        }
            break;
        case PLVChatMessageTypeReward: {
            messageType = @"PLVChatMessageTypeReward";
        }
            break;
        case PLVChatMessageTypeFlowers: {
            messageType = @"PLVChatMessageTypeFlowers";
        }
            break;
        case PLVChatMessageTypeKick: {
            messageType = @"PLVChatMessageTypeKick";
        }
            break;
        case PLVChatMessageTypeError: {
            messageType = @"PLVChatMessageTypeError";
        }
            break;
        case PLVChatMessageTypeElse: {
            messageType = @"PLVChatMessageTypeElse";
        }
            break;
        default:
            break;
    }
    
    RCTLogInfo(@"%@", messageType);
    RCTLogInfo(@"%@", chatObject.messageContent);
    RCTLogInfo(@"%@", chatObject.speaker);
    RCTLogInfo(@"%@", chatObject.messageAttributedContent);
    
    NSString *messageContent = @"";
    
    if (chatObject.messageContent) {
        messageContent = chatObject.messageContent;
    }
    
    NSString *nickName = @"";
    NSString *nickImg = @"";
    NSString *type = @"";
    
    if (chatObject.speaker) {
        nickName = chatObject.speaker.nickName;
        nickImg = chatObject.speaker.nickImg;
        type = chatObject.speaker.type;
    }
    
    if (self.onReceiveMessage) {
        self.onReceiveMessage(@{ @"target": self.reactTag,
                                 @"data" : @{@"messageType" : messageType,
                                             @"messageContent": messageContent,
                                             @"speaker": @{@"nickName": nickName,
                                                           @"nickImg": nickImg,
                                                           @"type": type
                                                           }
                                             }
                                 
                                 });
    }
}

- (void)socketIOConnectOnError:(PLVChatSocket *)chatSocket {
    RCTLogInfo(@"socket error");
}

- (void)socketIODidDisconnect:(PLVChatSocket *)chatSocket {
    RCTLogInfo(@"socket disconnect");
}

- (void)socketIOReconnect:(PLVChatSocket *)chatSocket {
    RCTLogInfo(@"socket reconnect");
}

- (void)socketIOReconnectAttempt:(PLVChatSocket *)chatSocket {
    RCTLogInfo(@"socket reconnectAttempt");
}

//获取到视频信息
- (void)movieNaturalSizeAvailable:(NSNotification *)notification {
    
}

//视频即将播放
- (void)mediaPlaybackIsPreparedToPlay:(NSNotification *)notification {
    
}

//视频播放状态
- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification {
    
    if (self.player.loadState & IJKMPMovieLoadStateStalled) {
        //RCTLogInfo(@"加载");
    } else if (self.player.loadState & IJKMPMovieLoadStatePlaythroughOK) {
        //RCTLogInfo(@"可播放");
    } else if (self.player.loadState & IJKMPMovieLoadStatePlayable) {
        //RCTLogInfo(@"可以播放");
    } else {
        
    }
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification {
    if (self.player.playbackState==IJKMPMoviePlaybackStatePlaying) {
        //开始播放
        if (self.onLoaded) {
            self.onLoaded(@{ @"target": self.reactTag});
        }
    } else if (self.player.playbackState == IJKMPMoviePlaybackStateStopped || self.player.playbackState == IJKMPMoviePlaybackStatePaused) {
        //暂停／停止播放
        if (self.onStop) {
            self.onStop(@{ @"target": self.reactTag});
        }
    }
}

//停止播放
- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification {
    //NSDictionary *dict = [notification userInfo];
    //NSNumber *finishReason =  dict[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    if(!newWindow) {
        [self releasePlayer];
        [self releaseChat];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if(!newSuperview) {
        [self releasePlayer];
        [self releaseChat];
    }
}

- (void)releaseTimer {
    if (liveStatusTimer) {
        [liveStatusTimer invalidate];
        liveStatusTimer = nil;
    }
    
    if (playerPollingTimer) {
        [playerPollingTimer invalidate];
        playerPollingTimer = nil;
    }
}

- (void)releaseChat {
    if (chatSocket) {
        [chatSocket disconnect];
        [chatSocket removeAllHandlers];
    }
}

- (void)releasePlayer {
    if(self.player) {
        [self.player.view removeFromSuperview];
        [self releaseTimer];
        [self.player shutdown];
        self.player = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

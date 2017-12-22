//
//  RCTPolyv.m
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/23.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import "RCTPolyv.h"
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import "Downloader.h"

@implementation RCTPolyv

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

RCT_EXPORT_METHOD(init:(NSString *)appId appKey:(NSString *)appKey appSecret:(NSString *)appSecret)
{
    NSArray *config = [PolyvUtil decryptUserConfig:[appKey dataUsingEncoding:NSUTF8StringEncoding]];
    [[PolyvSettings sharedInstance] initVideoSettings:[config objectAtIndex:1] Readtoken:[config objectAtIndex:2] Writetoken:[config objectAtIndex:3] UserId:[config objectAtIndex:0]];
    
    [[PolyvSettings sharedInstance] setDownloadDir:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/plvideo/a"]];
    
    [[PLVSettings sharedInstance] setAppId:appId appSecret:appSecret];
}

RCT_EXPORT_METHOD(download:(NSString *)vid level:(nonnull NSNumber *)level)
{
    if (!self.downloaders) self.downloaders = [[NSMutableDictionary alloc] init];
    
    PvUrlSessionDownload *_download = [[PvUrlSessionDownload alloc] initWithVid:vid level:1];
    [_download setDownloadDelegate:self];
    [_download start];
    
    if (!self.downloaders) self.downloaders = [[NSMutableDictionary alloc] init];
    
    [self.downloaders setValue:_download forKey:vid];
}

RCT_EXPORT_METHOD(start:(NSString *)vid)
{
    PvUrlSessionDownload* _download = [self.downloaders objectForKey:vid];
    
    if (_download) {
        if ([_download isStoped]) {
            [_download start];
        }
    }
}

RCT_EXPORT_METHOD(stop:(NSString *)vid)
{
    PvUrlSessionDownload* _download = [self.downloaders objectForKey:vid];
    
    if (_download) {
        if (![_download isStoped]) {
            [_download stop];
        }
    }
}

RCT_EXPORT_METHOD(delete:(NSString *)vid)
{
    [PvUrlSessionDownload deleteVideo:vid];
}

RCT_EXPORT_METHOD(clean)
{
    [PvUrlSessionDownload cleanDownload];
}

- (void)dataDownloadFailed:(PvUrlSessionDownload *)downloader withVid:(NSString *)vid reason:(NSString *)reason {
    [self.bridge.eventDispatcher sendAppEventWithName:@"Download" body:@{@"vid": vid, @"type": @"error", @"data": reason}];
}

- (void)dataDownloadAtPercent:(PvUrlSessionDownload *)downloader withVid:(NSString *)vid percent:(NSNumber *)aPercent
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"Download" body:@{@"vid": vid, @"type": @"progress", @"data": aPercent.stringValue}];
}

- (void)dataDownloadAtRate:(PvUrlSessionDownload *)downloader withVid:(NSString *)vid rate:(NSNumber *)aRate
{
    
}

- (void)downloader:(PvUrlSessionDownload *)downloader withVid:(NSString *)vid didChangeDownloadState:(PLVDownloadState)state
{
    switch (state) {
        case PLVDownloadStatePreparing:{
            //任务准备
        }break;
        case PLVDownloadStateReady:{
            //任务创建
        }break;
        case PLVDownloadStateRunning:{
            //任务开始
            [self.bridge.eventDispatcher sendAppEventWithName:@"Download" body:@{@"vid": vid, @"type": @"start", @"data": @""}];
        }break;
        case PLVDownloadStateStopping:{
            //正在停止
        }break;
        case PLVDownloadStateStopped:{
            //任务停止
            [self.bridge.eventDispatcher sendAppEventWithName:@"Download" body:@{@"vid": vid, @"type": @"pause", @"data": @""}];
        }break;
        case PLVDownloadStateSuccess:{
            //任务完成
            [self.bridge.eventDispatcher sendAppEventWithName:@"Download" body:@{@"vid": vid, @"type": @"done", @"data": @""}];
        }break;
        case PLVDownloadStateFailed:{
            
        }break;
        default:{}break;
    }
}

@end


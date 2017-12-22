//
//  Downloader.m
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/27.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import "Downloader.h"

@implementation DownloadParams

@end

@interface Downloader()

@property (copy) DownloadParams* params;

@end

@implementation Downloader

- (void)downloadFile:(DownloadParams*) params {
    PvUrlSessionDownload *_download = [[PvUrlSessionDownload alloc] initWithVid:params.vid level:params.level];
    [_download setDownloadDelegate:self];
    [_download start];
}

#pragma download delegate
- (void)dataDownloadFailed:(PvUrlSessionDownload *)downloader withVid:(NSString *)vid reason:(NSString *)reason {
    _params.errorCallback(vid, reason);
}

- (void)dataDownloadAtPercent:(PvUrlSessionDownload *)downloader withVid:(NSString *)vid percent:(NSNumber *)aPercent
{
    _params.progressCallback(vid, aPercent);
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
            _params.beginCallback(vid);
        }break;
        case PLVDownloadStateStopping:{
            //正在停止
        }break;
        case PLVDownloadStateStopped:{
            //任务停止
            _params.pauseCallback(vid);
        }break;
        case PLVDownloadStateSuccess:{
            //任务完成
            _params.completeCallback(vid);
        }break;
        case PLVDownloadStateFailed:{
            
        }break;
        default:{}break;
    }
}

@end

//
//  Downloader.h
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/27.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PvUrlSessionDownload.h"
#import "PvVideo.h"

typedef void (^DownloadCompleteCallback)(NSString*);
typedef void (^ErrorCallback)(NSString*, NSString*);
typedef void (^BeginCallback)(NSString*);
typedef void (^PauseCallback)(NSString*);
typedef void (^ProgressCallback)(NSString*, NSNumber*);

@interface DownloadParams : NSObject

@property (copy) NSString *vid;
@property        PvLevel level;
@property (copy) DownloadCompleteCallback completeCallback;
@property (copy) ErrorCallback errorCallback;
@property (copy) BeginCallback beginCallback;
@property (copy) PauseCallback pauseCallback;
@property (copy) ProgressCallback progressCallback;

@property        bool background;
@property (copy) NSNumber* progressDivider;

@end

@interface Downloader : NSObject <PvUrlSessionDownloadDelegate>
- (void)downloadFile:(DownloadParams*) params;
@end

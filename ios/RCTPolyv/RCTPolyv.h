//
//  RCTPolyv.h
//  RCTPolyv
//
//  Created by Fei Mo on 2017/11/23.
//  Copyright © 2017年 Fei Mo. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTLog.h>

#import "PolyvSettings.h"
#import "PolyvUtil.h"

#import "PvUrlSessionDownload.h"
#import "PvVideo.h"

#import <PLVLiveAPI/PLVSettings.h>

@interface RCTPolyv : NSObject <RCTBridgeModule, PvUrlSessionDownloadDelegate>
@property (retain) NSMutableDictionary* downloaders;
@end

//
//  VPHTTPRequestOperation.m
//  VPDownloadManager
//
//  Created by vernepung on 16/3/10.
//  Copyright © 2016年 vernepung. All rights reserved.
//

#import "VPHTTPRequestOperation.h"
@interface VPHTTPRequestOperation()
{
    
}
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

@implementation VPHTTPRequestOperation
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest
{
    self = [super initWithRequest:urlRequest];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    return self;
}
// 判断当前设备是否支持 后台多任务
- (BOOL)isMutiltaskingSupported{
    BOOL result = NO;
    if ( [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
        result = [[UIDevice currentDevice] isMultitaskingSupported];
    }
    return result;
}

- (void)enterForeground
{
    [self endBackground];
}


- (void)enterBackground
{
    if (![self isMutiltaskingSupported])
    {
        return;
    }
    @weakSelf(self);
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        @strongSelf(self);
        [self endBackground];
    }];
}

- (void)start
{
    [super start];
    self.downloadModel.downloadState = kVPDownloadStateDownloading;
}

- (void)cancel
{
    [super cancel];
    self.downloadModel.downloadState = kVPDownloadStatePause;
    self.downloadModel = nil;
    [self endBackground];
}


- (void)endBackground
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid)
        {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    });
}

@end

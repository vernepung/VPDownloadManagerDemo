//
//  VPHTTPRequestOperationManager.h
//  VPDownloadManager
//
//  Created by vernepung on 16/3/10.
//  Copyright © 2016年 vernepung. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"
#import "VPHTTPRequestOperation.h"
#import "BaseDownloadModel.h"

@interface VPHTTPRequestOperationManager : NSObject
+ (instancetype _Nonnull)manager;

- (void)pauseDownloadModel:(BaseDownloadModel * _Nonnull)model;

- (void)startNewDownloadWithModel:(BaseDownloadModel * _Nonnull)model;

- (NSArray<BaseDownloadModel *> * __nullable)getModelsWithState:(kVPDownloadState)state;

- (void)removeModelsWithState:(kVPDownloadState)state;

- (BaseDownloadModel * __nullable)isExistsModel:(BaseDownloadModel * _Nonnull)model;

- (void)clear;

- (void)save;

//+ (instancetype)managerWithMaxConcurrentOperationCount:(NSUInteger)count;
@end

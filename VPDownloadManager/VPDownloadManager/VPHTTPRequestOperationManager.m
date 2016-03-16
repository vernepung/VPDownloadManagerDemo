//
//  VPHTTPRequestOperationManager.m
//  VPDownloadManager
//
//  Created by vernepung on 16/3/10.
//  Copyright © 2016年 vernepung. All rights reserved.
//

#import "VPHTTPRequestOperationManager.h"
#import "VPHTTPRequestOperation.h"
#import "BaseDownloadModel.h"
#import "VPDownloadMacro.h"
@interface VPHTTPRequestOperationManager()
{
}
@property (strong,nonatomic) BaseDownloadModel *executingModel;
@property (strong,nonatomic) NSMutableArray *downloadModelArray;
@property (strong,nonatomic) NSMutableArray *operationArray;
@end
static VPHTTPRequestOperationManager *manager;
@implementation VPHTTPRequestOperationManager

+ (instancetype)manager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[super alloc] init];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 创建最外层目录
        [fileManager createDirectoryAtPath:kMainDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager createDirectoryAtPath:kTempDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager createDirectoryAtPath:kFileDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        if ([fileManager fileExistsAtPath:kCurrentUserConfigFilePath])
        {
            manager.downloadModelArray = [NSKeyedUnarchiver unarchiveObjectWithFile:kCurrentUserConfigFilePath];
            NSArray *downloadingArray = [manager.downloadModelArray filteredArrayUsingPredicate:[manager getPredicateWithState:kVPDownloadStateDownloading]];
            NSArray *watingArray = [manager.downloadModelArray filteredArrayUsingPredicate:[manager getPredicateWithState:kVPDownloadStateWaiting]];
            if (downloadingArray.count > 0)
            {
                for (BaseDownloadModel *model in downloadingArray) {
                    model.downloadState = [model isCompleted] ? kVPDownloadStateCompleted : kVPDownloadStatePause;
                }
            }
            if (watingArray.count > 0)
            {
                for (BaseDownloadModel *model in watingArray) {
                    model.downloadState = [model isCompleted] ? kVPDownloadStateCompleted : kVPDownloadStatePause;
                }
            }
        }
    });
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        NSLog(@"AFNetworkReachabilityStatus");
        if (status != AFNetworkReachabilityStatusReachableViaWiFi)
        {
            [manager cancelAll];
        }
        else if (status == AFNetworkReachabilityStatusReachableViaWiFi)
        {
            //            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //                [manager restartAll];
            //            });
        }
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = [NSString stringWithFormat:@"网络切换了...Wifi:%zd",status];
        notification.applicationIconBadgeNumber = 1;
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            UIUserNotificationType type =  UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type
                                                                                     categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        } else {
        }
        // 执行通知注册
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }];
    return manager;
}

- (void)startNewDownloadWithModel:(BaseDownloadModel * _Nonnull)model
{
    VPHTTPRequestOperation *vpOperation = [self getOperationWithModel:model];
    if (model.downloadState == kVPDownloadStatePause && vpOperation)
    {
        if (self.executingModel)
        {
            model.downloadState = kVPDownloadStateWaiting;
        }
        else
        {
            [self startOperation:vpOperation];
        }
    }
    else if (model.downloadState != kVPDownloadStateDownloading && model.downloadState != kVPDownloadStateWaiting)
    {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:model.fileUrl] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:model.fileTempPath])
        {
            model.readedBytes = [[[NSFileManager defaultManager] attributesOfItemAtPath:model.fileTempPath error:nil] fileSize];
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", model.readedBytes];
            [request setValue:requestRange forHTTPHeaderField:@"Range"];
        }
        else
        {
            model.readedBytes = 0;
        }
        
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
        vpOperation = [[VPHTTPRequestOperation alloc] initWithRequest:request];
        vpOperation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                                 @"video/mp4",
                                                                 @"application/pdf",
                                                                 @"application/msword",
                                                                 @"text/plain",
                                                                 @"application/vnd.ms-powerpoint",
                                                                 @"application/vnd.ms-excel",
                                                                 @"application/octet-stream", nil];
        vpOperation.downloadModel = model;
        [vpOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            VPHTTPRequestOperation *completedOperation = (VPHTTPRequestOperation *)operation;
            [completedOperation.downloadModel copyFileToNormallyPath];
            void (^changedBlock)() = ^(){
                completedOperation.downloadModel.downloadState = kVPDownloadStateCompleted;
                completedOperation.downloadModel = nil;
                [completedOperation endBackground];
                [manager.operationArray removeObject:completedOperation];
                [manager moveNext];
                [manager save];
            };
            if ([NSThread isMainThread])
            {
                changedBlock();
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    changedBlock();
                });
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (operation.isCancelled)
            {
                [manager save];
                return ;
            }
            if ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable)
            {
                [manager cancelAll];
                [manager save];
                return;
            }
            void (^changedBlock)() = ^(){
                VPHTTPRequestOperation *tempOperation = (VPHTTPRequestOperation *)operation;
                if (tempOperation.downloadModel.downloadState != kVPDownloadStatePause)
                {
                    tempOperation.downloadModel.downloadState = kVPDownloadStateError;
                    tempOperation.downloadModel = nil;
                    [tempOperation endBackground];
                    [manager.operationArray removeObject:tempOperation];
                }
                [self moveNext];
                [manager save];
            };
            if ([NSThread isMainThread])
            {
                changedBlock();
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    changedBlock();
                });
            }
        }];
        
        [vpOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            //            NSLog(@"%zd_%llu_%llu",bytesRead,totalBytesRead,totalBytesExpectedToRead);
            void (^changedBlock)() = ^(){
                model.totalBytes = totalBytesExpectedToRead;
                model.readedBytes = model.readedBytes + bytesRead;
            };
            if ([NSThread isMainThread])
            {
                changedBlock();
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    changedBlock();
                });
            }
        }];
        vpOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:model.fileTempPath append:YES];
        [self.operationArray addObject:vpOperation];
        if (self.executingModel)
        {
            model.downloadState = kVPDownloadStateWaiting;
        }
        else
        {
            [self startOperation:vpOperation];
        }
        if (![self isExistsModel:model])
        {
            [self.downloadModelArray addObject:model];
        }
    }
}

- (void)pauseDownloadModel:(BaseDownloadModel *)model
{
    for (VPHTTPRequestOperation *vpOperation in self.operationArray) {
        if ([vpOperation.downloadModel isEqual:model])
        {
            [vpOperation cancel];
            [self.operationArray removeObject:vpOperation];
            break;
        }
    }
    if ([self.executingModel isEqual:model])
    {
        self.executingModel = nil;
    }
    if (!self.executingModel)
    {
        [self moveNext];
    }
}

- (BaseDownloadModel *)isExistsModel:(BaseDownloadModel *)model
{
    if (self.downloadModelArray && self.downloadModelArray.count > 0)
    {
        NSArray *searchResultArray = [self.downloadModelArray filteredArrayUsingPredicate:[self getPredicateWithHash:[model hash]]];
        if (searchResultArray.count > 0)
        {
            return searchResultArray[0];
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

- (void)removeModelsWithState:(kVPDownloadState)state
{
    NSArray *stateModelArray = [self.downloadModelArray filteredArrayUsingPredicate:[self getPredicateWithState:state]];
    for (NSInteger index = stateModelArray.count - 1; index >= 0; index--) {
        BaseDownloadModel *downloadModel = stateModelArray[index];
        VPHTTPRequestOperation *vpOperation = [self getOperationWithModel:downloadModel];
        if (vpOperation)
        {
            [vpOperation cancel];
            vpOperation.downloadModel = nil;
            [self.operationArray removeObject:vpOperation];
        }
        [downloadModel removeFiles];
        [self.downloadModelArray removeObject:downloadModel];
    }
}

- (void)save
{
//    [self.downloadModelArray writeToFile:kCurrentUserConfigFilePath atomically:YES];
    [NSKeyedArchiver archiveRootObject:self.downloadModelArray toFile:kCurrentUserConfigFilePath];
}

- (void)clear
{
    [manager cancelAll];
    [manager.operationArray removeAllObjects];
    manager.operationArray = nil;
    [manager.downloadModelArray removeAllObjects];
    manager.downloadModelArray = nil;
    [[NSFileManager defaultManager] removeItemAtPath:kCurrentUserConfigFilePath error:nil];
}

- (NSArray<BaseDownloadModel *> *)getModelsWithState:(kVPDownloadState)state
{
    return [self.downloadModelArray filteredArrayUsingPredicate:[self getPredicateWithState:state]];
}

#pragma mark - private function
- (void)startOperation:(VPHTTPRequestOperation *)operation
{
    if (![self.executingModel isEqual:operation.downloadModel])
    {
        VPHTTPRequestOperation *vpOperation = [manager getOperationWithModel:self.executingModel];
        if (vpOperation)
        {
            [vpOperation cancel];
        }
        self.executingModel = operation.downloadModel;
    }
    if (!operation.isExecuting)
    {
        [operation start];
    }
}

- (void)moveNext
{
    NSArray *arr = [self.operationArray filteredArrayUsingPredicate:[self getPredicateWithModelState:kVPDownloadStateWaiting]];
    if (arr.count > 0)
    {
        VPHTTPRequestOperation *operation = (VPHTTPRequestOperation *)arr[0];
        [self startOperation:operation];
    }
    else
    {
        self.executingModel = nil;
    }
}

- (VPHTTPRequestOperation *)getOperationWithModel:(BaseDownloadModel *)model
{
    if (self.operationArray && self.operationArray.count > 0)
    {
        NSString *searchStr = [NSString stringWithFormat:@"downloadModel.hash == %zd",[model hash]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:searchStr];
        NSArray *resultArray = [self.operationArray filteredArrayUsingPredicate:predicate];
        if (resultArray.count == 1)
        {
            return (VPHTTPRequestOperation *)resultArray[0];
        }
        else
        {
            return nil;
        }
    }
    return nil;
}

#pragma mark - private function
- (void)cancelAll
{
    for (NSInteger index = self.operationArray.count - 1; index >= 0; index --) {
        VPHTTPRequestOperation *vpOperation = (VPHTTPRequestOperation *)self.operationArray[index];
        [vpOperation cancel];
        [manager.operationArray removeObject:vpOperation];
    }
    self.executingModel = nil;
}


- (void)restartAll
{
    NSArray *pauseArray = [self.downloadModelArray filteredArrayUsingPredicate:[self getPredicateWithState:kVPDownloadStatePause]];
    for (BaseDownloadModel *pauseModel in pauseArray) {
        [manager startNewDownloadWithModel:pauseModel];
    }
}

- (NSPredicate *)getPredicateWithModelState:(kVPDownloadState)state
{
    NSString *searchStr = [NSString stringWithFormat:@"downloadModel.downloadState == %zd",state];
    return [self getPredicateWithString:searchStr];
}

- (NSPredicate *)getPredicateWithModelHash:(NSUInteger)hash
{
    NSString *searchStr = [NSString stringWithFormat:@"downloadModel.hash == %zd",hash];
    return [self getPredicateWithString:searchStr];
}

- (NSPredicate *)getPredicateWithState:(kVPDownloadState)state
{
    NSString *searchStr = [NSString stringWithFormat:@"downloadState == %zd",state];
    return [self getPredicateWithString:searchStr];
}

- (NSPredicate *)getPredicateWithHash:(NSUInteger)hash
{
    NSString *searchStr = [NSString stringWithFormat:@"hash == %zd",hash];
    return [self getPredicateWithString:searchStr];
}

- (NSPredicate *)getPredicateWithString:(NSString *)str
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:str];
    return predicate;
}

- (NSMutableArray *)downloadModelArray
{
    if (!_downloadModelArray)
    {
        _downloadModelArray = [[NSMutableArray alloc]init];
    }
    return _downloadModelArray;
}

- (NSMutableArray *)operationArray
{
    if (!_operationArray)
    {
        _operationArray = [[NSMutableArray alloc] init];
    }
    return _operationArray;
}

@end

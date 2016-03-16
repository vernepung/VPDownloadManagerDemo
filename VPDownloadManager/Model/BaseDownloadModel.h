//
//  BaseDownloadModel.h
//  VPDownloadManager
//
//  Created by vernepung on 16/3/10.
//  Copyright © 2016年 vernepung. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 *  下载状态
 */
typedef NS_OPTIONS(NSUInteger, kVPDownloadState)
{
    /**
     *  未开始下载
     */
    kVPDownloadStateNormal      = 0,
    /**
     *  正在下载
     */
    kVPDownloadStateDownloading = 1 << 0,
    /**
     *  等待
     */
    kVPDownloadStateWaiting     = 1 << 1,
    /**
     *  暂停
     */
    kVPDownloadStatePause       = 1 << 2,
    /**
     *  完成
     */
    kVPDownloadStateCompleted   = 1 << 3,
    /**
     *  下载错误
     */
    kVPDownloadStateError      = 1 << 4,
    /**
     *  下载错误
     */
    kVPDownloadStateNoNetWork      = 1 << 5,
};

@interface BaseDownloadModel : NSObject<NSCoding>

@property (copy,nonatomic) NSString *mainId;

@property (assign,nonatomic) kVPDownloadState downloadState;

@property (assign,nonatomic) long long readedBytes;

@property (assign,nonatomic) long long totalBytes;

@property (copy,nonatomic) NSString *fileUrl;

@property (readonly,copy,nonatomic) NSString *fileTempPath;

@property (readonly,copy,nonatomic) NSString *filePath;

- (void)copyFileToNormallyPath;

- (void)removeFiles;

- (BOOL)isCompleted;
@end

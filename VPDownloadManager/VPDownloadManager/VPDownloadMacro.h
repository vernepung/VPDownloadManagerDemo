//
//  Header.h
//  VPDownloadManager
//
//  Created by vernepung on 16/3/15.
//  Copyright © 2016年 vernepung. All rights reserved.
//

#ifndef Header_h
#define Header_h
#import <UIKit/UIKit.h>

#define kMainDirectoryPath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"DownloadFiles"]stringByAppendingPathComponent:kUserId]

#define kTempDirectoryPath [kMainDirectoryPath stringByAppendingPathComponent:@"Temp"]

#define kFileDirectoryPath [kMainDirectoryPath stringByAppendingPathComponent:@"Files"]

#define kCurrentUserConfigFilePath [kMainDirectoryPath stringByAppendingPathComponent:kUserId]
// test
#define kUserId @"vernePung_123"
#endif /* Header_h */

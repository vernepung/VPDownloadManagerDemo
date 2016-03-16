//
//  VPHTTPRequestOperation.h
//  VPDownloadManager
//
//  Created by vernepung on 16/3/10.
//  Copyright © 2016年 vernepung. All rights reserved.
//
#pragma mark - 弱引用self
#if DEBUG
#define ext_keywordify autoreleasepool {}
#else
#define ext_keywordify try {} @catch (...) {}
#endif


#define weakSelf(VAR) \
ext_keywordify \
__weak __typeof(&*VAR) __weak##VAR = VAR;
#define strongSelf(VAR) \
ext_keywordify \
__strong __typeof(&*VAR) VAR = __weak##VAR;
#import "AFHTTPRequestOperation.h"
#import "BaseDownloadModel.h"

@interface VPHTTPRequestOperation : AFHTTPRequestOperation
@property (strong,atomic) BaseDownloadModel *downloadModel;
- (void)endBackground;
@end

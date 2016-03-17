//
//  BaseDownloadModel.m
//  VPDownloadManager
//
//  Created by vernepung on 16/3/10.
//  Copyright © 2016年 vernepung. All rights reserved.
//

#import "BaseDownloadModel.h"
#import "VPDownloadMacro.h"
typedef uint32_t CC_LONG;       /* 32 bit unsigned integer */
extern unsigned char *CC_MD5(const void *data, CC_LONG len, unsigned char *md)
__OSX_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_2_0);

@interface BaseDownloadModel()
{
    
}
@end

@implementation BaseDownloadModel
@synthesize fileTempPath = _fileTempPath, filePath = _filePath;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _mainId = [[aDecoder decodeObjectForKey:@"_mainId"] copy];
        _downloadState = [aDecoder decodeIntegerForKey:@"_downloadState"];
        _totalBytes = [aDecoder decodeInt64ForKey:@"_totalBytes"];
        _fileUrl = [[aDecoder decodeObjectForKey:@"_fileUrl"] copy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_mainId forKey:@"_mainId"];
    [aCoder encodeInteger:_downloadState forKey:@"_downloadState"];
    [aCoder encodeInt64:_totalBytes forKey:@"_totalBytes"];
    [aCoder encodeObject:_fileUrl forKey:@"_fileUrl"];
}

- (NSString*)md5:(NSString *)value {
    const char* string = [value UTF8String];
    unsigned char result[16];
    CC_MD5(string, (uint)strlen(string), result);
    NSString* hash = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                      result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
                      result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
    
    return [hash lowercaseString];
}

- (BOOL)isCompleted
{
    if (self.downloadState == kVPDownloadStateCompleted)
    {
        return YES;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath])
    {
        self.readedBytes = self.totalBytes;
        return YES;
    }
    if (self.totalBytes > 0 && self.readedBytes > 0 &&  self.readedBytes == self.totalBytes)
    {
        [self copyFileToNormallyPath];
        return YES;
    }
    return NO;
}

- (void)copyFileToNormallyPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager isExecutableFileAtPath:self.filePath])
    {
        [fileManager removeItemAtPath:self.filePath error:nil];
    }
    NSError *error;
    BOOL copied = [fileManager copyItemAtPath:self.fileTempPath toPath:self.filePath error:&error];
    if (copied && !error)
    {
        [fileManager removeItemAtPath:self.fileTempPath error:nil];
    }
    
}

- (void)removeFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager isExecutableFileAtPath:self.filePath])
    {
        [fileManager removeItemAtPath:self.fileTempPath error:nil];
    }
    if ([fileManager isExecutableFileAtPath:self.fileTempPath])
    {
        [fileManager removeItemAtPath:self.fileTempPath error:nil];
    }
}

- (NSString *)fileTempPath
{
    if (!_fileTempPath)
    {
        _fileTempPath = [kTempDirectoryPath stringByAppendingPathComponent:[self md5:_fileUrl]];
    }
    return _fileTempPath;
}

- (NSString *)filePath
{
    if (!_filePath)
    {
        _filePath = [kFileDirectoryPath stringByAppendingPathComponent:[self md5:_fileUrl]];
    }
    return _filePath;
}

- (NSString *)fileUrl
{
    if (_fileUrl && _fileUrl.length > 0)
    {
        NSString *temp = [NSString stringWithFormat:@"random=%zd",arc4random()];
        if ([_fileUrl rangeOfString:@"?"].location != NSNotFound)
        {
            return [_fileUrl stringByAppendingString:[NSString stringWithFormat:@"&%@",temp]];
        }
        else
        {
            return [_fileUrl stringByAppendingString:[NSString stringWithFormat:@"?%@",temp]];
        }
    }
    return _fileUrl;
}

- (long long)readedBytes
{
    if (_readedBytes <= 0)
    {
        _readedBytes = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.fileTempPath error:nil] fileSize];
    }
    return _readedBytes;
}

- (void)setTotalBytes:(long long)totalBytes
{
    if (_totalBytes <= 0)
    {
        _totalBytes = totalBytes;
    }
}

- (void)setDownloadState:(kVPDownloadState)downloadState
{
    if (_downloadState != downloadState)
    {
        _downloadState = downloadState;
    }
}

- (NSUInteger)hash
{
    return [self.mainId hash];
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
    return [self hash] == [object hash];
}
@end

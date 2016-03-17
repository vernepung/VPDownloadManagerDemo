//
//  BaseDownloadCell.m
//  VPDownloadManager
//
//  Created by vernepung on 16/3/10.
//  Copyright © 2016年 vernepung. All rights reserved.
//

#import "BaseDownloadCell.h"
static void * const VPOBSERVERCONTEXTKEY = @"VPOBSERVERCONTEXTKEY";
@interface BaseDownloadCell ()
{

}
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UILabel *downloadBytesLabel;
@end

@implementation BaseDownloadCell

- (void)dealloc
{
    [self removeObserver];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)removeObserver
{
    [_currentModel removeObserver:self forKeyPath:@"downloadState" context:VPOBSERVERCONTEXTKEY];
    [_currentModel removeObserver:self forKeyPath:@"readedBytes" context:VPOBSERVERCONTEXTKEY];
}

- (void)setCurrentModel:(BaseDownloadModel *)currentModel
{
    if (_currentModel)
    {
        [self removeObserver];
    }
    if (currentModel)
    {
        [currentModel addObserver:self forKeyPath:@"downloadState" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:VPOBSERVERCONTEXTKEY];
        [currentModel addObserver:self forKeyPath:@"readedBytes" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:VPOBSERVERCONTEXTKEY];
        self.downloadBytesLabel.text = [NSString stringWithFormat:@"%@MB/%@MB",[self getSize:currentModel.readedBytes],[self getSize:currentModel.totalBytes]];
        [self.downloadBytesLabel sizeToFit];
    }
    _currentModel = currentModel;
    switch (_currentModel.downloadState) {
        case kVPDownloadStateNormal:
            self.stateLabel.text = @"Normal";
            break;
        case kVPDownloadStateWaiting:
            self.stateLabel.text = @"Waiting";
            break;
        case kVPDownloadStateDownloading:
            self.stateLabel.text = @"Downloading";
            break;
        case kVPDownloadStatePause:
            self.stateLabel.text = @"Pause";
            break;
        case kVPDownloadStateCompleted:
            self.stateLabel.text = @"Completed";
            break;
        case kVPDownloadStateError:
            self.stateLabel.text = @"Error";
            break;
        case kVPDownloadStateNoNetWork:
            self.stateLabel.text = @"后台监听正常";
            break;
    }
    self.downloadBytesLabel.text = [NSString stringWithFormat:@"%@MB/%@MB",[self getSize:self.currentModel.readedBytes],[self getSize:self.currentModel.totalBytes]];
    [self.downloadBytesLabel sizeToFit];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
//    NSLog(@"changed %@",keyPath);
    if ([keyPath isEqualToString:@"downloadState"])
    {
        switch (self.currentModel.downloadState) {
            case kVPDownloadStateNormal:
                self.stateLabel.text = @"Normal";
                break;
            case kVPDownloadStateWaiting:
                self.stateLabel.text = @"Waiting";
                break;
            case kVPDownloadStateDownloading:
                self.stateLabel.text = @"Downloading";
                break;
            case kVPDownloadStatePause:
                self.stateLabel.text = @"Pause";
                break;
            case kVPDownloadStateCompleted:
                self.stateLabel.text = @"Completed";
                break;
            case kVPDownloadStateError:
                self.stateLabel.text = @"Error";
                break;
            case kVPDownloadStateNoNetWork:
                self.stateLabel.text = @"后台监听正常";
                break;
        }
        [self downloadStateChanged];
    }
    else if ([keyPath isEqualToString:@"readedBytes"])
    {
        [self readedBytesUpdated];
    }
}

- (void)downloadStateChanged
{
    self.stateLabel.text = [self.stateLabel.text stringByAppendingString:self.currentModel.mainId];
}

- (void)readedBytesUpdated
{
    self.downloadBytesLabel.text = [NSString stringWithFormat:@"%@MB/%@MB",[self getSize:self.currentModel.readedBytes],[self getSize:self.currentModel.totalBytes]];
    [self.downloadBytesLabel sizeToFit];
}

// downloadStateChanged
// readedbytesUpdate

- (NSString *)getSize:(long long)bytes
{
    CGFloat size = bytes / 1024.f / 1024.f;
    return [NSString stringWithFormat:@"%.1f",size];
}

+ (instancetype)initCellFromXibWithTableView:(UITableView *)tableView
{
    id cell = [tableView dequeueReusableCellWithIdentifier:[[self class] cellIdentifier]];
    if (!cell)
    {
        cell = [[self class] loadFromXib];
    }
    return cell;
}

+ (id)loadFromXib
{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:self options:nil]lastObject];
}

+ (NSString*)cellIdentifier
{
    return NSStringFromClass(self);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}


@end

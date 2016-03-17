//
//  ViewController.m
//  VPDownloadManager
//
//  Created by vernepung on 16/3/10.
//  Copyright © 2016年 vernepung. All rights reserved.
//

#import "ViewController.h"
#import "BaseDownloadModel.h"
#import "BaseDownloadCell.h"
#import "VPHTTPRequestOperationManager.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray *_array;
}
@property (strong,nonatomic) UITableView *testTableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *arr = @[@"http://dlsw.baidu.com/sw-search-sp/soft/9d/25765/sogou_mac_32c_V3.2.0.1437101586.dmg",
                     @"http://myvideo.open.com.cn/Dxztc/Attachment/Video/005/20131129093958.mp4",
                     @"http://myvideo.open.com.cn/Dxztc/Attachment/Video/005/20131129093547.mp4",
                     @"http://myvideo.open.com.cn/Dxztc/Attachment/Video/005/20131129093221.mp4",
                     @"http://myvideo.open.com.cn/Dxztc/Attachment/Video/005/20131129093024.mp4",
                     @"http://myvideo.open.com.cn/Dxztc/Attachment/Video/005/20131129092501.mp4",
                     @"http://myvideo.open.com.cn/Dxztc/Attachment/Video/005/20131129092134.mp4",
                     @"http://myvideo.open.com.cn/Dxztc/Attachment/Video/005/20131128033936.mp4"];
    self.testTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 85, 300, 500)];
    self.testTableView.delegate = self;
    self.testTableView.dataSource = self;
    self.testTableView.backgroundColor = [UIColor purpleColor];
    [self.view addSubview:self.testTableView];
    _array = [NSMutableArray array];
    BaseDownloadModel *model = nil;
    for (NSInteger i = 0; i < arr.count ; i++) {
        model = [[BaseDownloadModel alloc]init];
        model.mainId = [NSString stringWithFormat:@"_%zd",i];
        model.fileUrl = arr[i];
        BaseDownloadModel *temp = [[VPHTTPRequestOperationManager manager] isExistsModel:model];
        if (temp)
        {
            model = temp;
        }
        [_array addObject:model];
    }
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    BaseDownloadModel *model = _array[row];
    if (model.downloadState == kVPDownloadStateDownloading || model.downloadState == kVPDownloadStateWaiting)
    {
        [[VPHTTPRequestOperationManager manager] pauseDownloadModel:model];
    }
    else if (model.downloadState == kVPDownloadStateCompleted)
    {
        return;
    }
    else
    {
        [[VPHTTPRequestOperationManager manager] startNewDownloadWithModel:model];
    }
    //    else
    //    {
    //    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    BaseDownloadModel *model = _array[row];
    
    BaseDownloadCell *cell = [BaseDownloadCell initCellFromXibWithTableView:tableView];
    cell.currentModel = model;
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}

#pragma mark -


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

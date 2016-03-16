//
//  BaseDownloadCell.h
//  VPDownloadManager
//
//  Created by vernepung on 16/3/10.
//  Copyright © 2016年 vernepung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDownloadModel.h"
@interface BaseDownloadCell : UITableViewCell
@property (strong,nonatomic) BaseDownloadModel *currentModel;


+ (instancetype)initCellFromXibWithTableView:(UITableView *)tableView;
@end

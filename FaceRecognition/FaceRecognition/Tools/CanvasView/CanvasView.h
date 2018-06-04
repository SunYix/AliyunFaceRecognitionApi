//
//  CanvasView.h
//
//  Created by xiaoka on 2018/5/10.
//  Copyright © 2018年 sunyi. All rights reserved.
//
//  脸部轮廓方框页面

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface CanvasView : UIView

#define POINTS_KEY @"POINTS_KEY"
#define RECT_KEY   @"RECT_KEY"
#define RECT_ORI   @"RECT_ORI"

@property (nonatomic , strong) NSArray *arrPersons ;
@property (nonatomic , strong) NSArray *arrFixed;

@end

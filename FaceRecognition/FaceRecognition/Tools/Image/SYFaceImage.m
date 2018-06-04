//
//  SYFaceImage.m
//  FaceRecognition
//
//  Created by xiaoka on 2018/5/10.
//  Copyright © 2018年 sunyi. All rights reserved.
//

#import "SYFaceImage.h"
#import "UIImage+Extensions.h"

#import "CalculatorTools.h"


@implementation SYFaceImage

@synthesize data=_data;

-(instancetype)init{
    if (self=[super init]) {
        _data=nil;
        self.width=0;
        self.height=0;
        self.direction=IFlyFaceDirectionTypeLeft;
    }
    
    return self;
}

-(void)dealloc{
    self.data=nil;
}

@end

//
//  PermissionDetector.h
//  FaceRecognition
//
//  Created by xiaoka on 2018/5/10.
//  Copyright © 2018年 sunyi. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface PermissionDetector : NSObject

/**
 *  检测麦克风权限，仅支持iOS7.0以上系统
 *
 *  @return 准许返回YES;否则返回NO
 */
+(BOOL)isMicrophonePermissionGranted;

/**
 *  检测相机权限
 *
 *  @return 准许返回YES;否则返回NO
 */
+(BOOL)isCapturePermissionGranted;

/**
 *  检测相册权限
 *
 *  @return 准许返回YES;否则返回NO
 */
+(BOOL)isAssetsLibraryPermissionGranted;

@end

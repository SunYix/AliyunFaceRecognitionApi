//
//  SYFaceDetectNetwork.h
//  FaceRecognition
//
//  Created by xiaoka on 2018/5/10.
//  Copyright © 2018年 sunyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYFaceImage.h"

@interface SYFaceDetectNetwork : NSObject


/**
 *  单例模式
 *
 *  @return EMConfigUtils instance
 */
+ (instancetype)singleton;



/**
 *  请求阿里人脸api
 */
- (void)postFaceDetecRequestNetworkWithFaceImage:(SYFaceImage *)faceImage atCallback:(void(^)(NSString *))callback;

@end

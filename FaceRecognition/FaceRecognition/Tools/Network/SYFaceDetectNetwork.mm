//
//  SYFaceDetectNetwork.m
//  FaceRecognition
//
//  Created by xiaoka on 2018/5/10.
//  Copyright © 2018年 sunyi. All rights reserved.
//

#import "SYFaceDetectNetwork.h"

#include <CommonCrypto/CommonDigest.h>
//#include <CommonCrypto/CommonHMAC.h>
#include "base64.h"
//#include <string.h>

#include "Utils.h"
#include "common.h"

static SYFaceDetectNetwork *instance;
@implementation SYFaceDetectNetwork

/**
 *  app配置单例
 *
 *  @return
 */
+ (instancetype)singleton
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[SYFaceDetectNetwork alloc] init];
    });
    
    return instance;
}

- (void)postFaceDetecRequestNetworkWithFaceImage:(SYFaceImage *)faceImage atCallback:(void(^)(NSString *))callback
{
    std::string ak_id = "此处填写阿里云的id";
    std::string ak_secret = "此处填写阿里云的secret";
    //OC
    NSString *host = @"https://dtplus-cn-shanghai.data.aliyuncs.com";
    NSString *path_oc = @"/face/detect";
    NSString *method_oc = @"POST";
    NSString *url = [NSString stringWithFormat:@"%@%@",  host,  path_oc ];
    NSString *date_oc = [self currentDate];
    
    //C++
    std::string method = "POST";
    std::string accept = "application/json";
    std::string content_type = "application/json";
    std::string path = "/face/detect";
    std::string date = Utils::GetGMTDatetime();
    
    NSDictionary * detailDic = @{@"type":@1,
                                 @"image_url":@"",
                                 @"content":[self encode:faceImage.data]
                                };
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:detailDic options:0 error:nil];
    NSString * bodys = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    const char * filePathChar = [bodys UTF8String];
    std::string bodyMd5str = Utils::Md5Base64(filePathChar);
    std::string stringToSign = method + "\n" + accept + "\n" + bodyMd5str + "\n" + content_type + "\n" + date + "\n" + path;
    std::string signature = Utils::HMACSha1Base64(stringToSign, ak_secret);
    std::string authHeader = "Dataplus " + ak_id + ":" + signature;
 
    NSString *authHeader_oc = [NSString stringWithCString:authHeader.c_str()
                                                encoding:[NSString defaultCStringEncoding]];
    date_oc = [NSString stringWithCString:date.c_str()
                                 encoding:[NSString defaultCStringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: url]  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData  timeoutInterval:  10];
    request.HTTPMethod  =  method_oc;
    [request addValue: authHeader_oc  forHTTPHeaderField:  @"Authorization"];
    [request addValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
    [request addValue:date_oc forHTTPHeaderField:@"Date"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    

    [request setHTTPBody: jsonData];
    NSURLSession *requestSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [requestSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable body , NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                            
           NSLog(@"Response object: %@" , response);
           NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
           
           //打印应答中的body
           NSLog(@"Response body: %@" , bodyString);
                                                       NSLog(@"error---%@",error);
           callback(bodyString);
    }];
    
    [task resume];
}



/**
 * base64编码

 @param string
 @return
 */
- (NSString *)encode:(NSData *)data
{
    NSData *base64Data = [data base64EncodedDataWithOptions:0];
    
    NSString *baseString = [[NSString alloc]initWithData:base64Data encoding:NSUTF8StringEncoding];
    
    
    
    return baseString;
}


- (NSString *)encodeWithString:(NSString *)string
{
    //先将string转换成data
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *base64Data = [data base64EncodedDataWithOptions:0];
    
    NSString *baseString = [[NSString alloc]initWithData:base64Data encoding:NSUTF8StringEncoding];
    
    return baseString;
}






- (NSString *)currentDate
{
    NSDate *date = [NSDate date];
    
    NSTimeZone *tzGMT = [NSTimeZone timeZoneWithName:@"GMT"];
    [NSTimeZone setDefaultTimeZone:tzGMT];
    
    NSDateFormatter *iosDateFormater=[[NSDateFormatter alloc]init];
    
    iosDateFormater.dateFormat=@"EEE, d MMM yyyy HH:mm:ss 'GMT'";
    
    iosDateFormater.locale=[[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
    NSString *dateStr = [iosDateFormater stringFromDate:date];
    return dateStr;
}




@end

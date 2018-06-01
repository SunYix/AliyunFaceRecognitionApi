# AliyunFaceRecognitionApi

####采用阿里云提供的人脸检测识别api


``` 
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
    ```
#####需要注意是请求头中要加Authorization和中间的md5、base64加签
      如果您喜欢这个阿里云人脸检测识别Demo的话，希望给个star～～～～～
           
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: url]  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData  timeoutInterval:  10];

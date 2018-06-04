//
//  EMFaceStreamViewController.m
//  FaceRecognition
//
//  Created by xiaoka on 2018/5/10.
//  Copyright © 2018年 sunyi. All rights reserved.
//

#import "EMFaceStreamViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "PermissionDetector.h"
#import "UIImage+Extensions.h"
#import "UIImage+compress.h"
#import "DemoPreDefine.h"
#import "CaptureManager.h"
#import "CanvasView.h"
#import "CalculatorTools.h"
#import "UIImage+Extensions.h"
#import "SYFaceImage.h"
#import "SYFaceResultKeys.h"
#import "SYFaceDetectNetwork.h"
#import "SVProgressHUD.h"

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && DEVICE_HEIGHT < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && DEVICE_HEIGHT == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && DEVICE_HEIGHT == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && DEVICE_HEIGHT == 736.0)


@interface EMFaceStreamViewController ()<CaptureManagerDelegate>
{
    UILabel *alignLabel;
    int number;
    int takePhotoNumber;
    NSTimer *timer;
    NSInteger timeCount;
    UIImageView *imgView;//动画图片展示
    
    //拍照操作
    AVCaptureStillImageOutput *myStillImageOutput;
    UIView *backView;//照片背景
    UIImageView *imageView;//照片展示
    
    BOOL _isCrossBorder;//判断是否越界
    BOOL _isSeeFace;//判断正脸操作完成
    BOOL _isJudgeMouth;//判断张嘴操作完成
    BOOL _isLeftFace;//判断左侧脸操作完成
    BOOL _isRightFace;//判断右侧脸操作完成
    BOOL _isShakeHead;//判断摇头操作完成
    
    //嘴角坐标
    int leftX;
    int rightX;
    int lowerY;
    int upperY;
    
    //眉毛边坐标
    int rightBrow_rightX;
    int rightBrow_leftX;
    int leftBrow_leftX;
    int leftBrow_rightX;
    
    //嘴型的宽高（初始的和后来变化的）
    int mouthWidthF;
    int mouthHeightF;
    int mouthWidth;
    int mouthHeight;
    
    //记录摇头嘴中点的数据
    int bigNumber;
    int smallNumber;
    int firstNumber;
    
    BOOL _isChange;//是否改变api
    
    SYFaceImage * _saveFaceImage;
    BOOL _isOpenPath; //是否开放调用路径
    BOOL _isCameraman;//是否可以拍照
    NSTimer * _timer;
    
}


@property (nonatomic, retain ) UIView                     *previewView;
@property (nonatomic, weak ) IBOutlet UILabel             *textLabel;

@property (nonatomic, retain ) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain ) CaptureManager             *captureManager;

@property (nonatomic, strong ) CanvasView                 *viewCanvas;
@property (nonatomic, strong ) UITapGestureRecognizer     *tapGesture;
/** 存储照片数组 */
@property (strong, nonatomic) NSMutableArray     *photoArray;
/** 照相按钮/倒计时 */
@property (weak, nonatomic) IBOutlet UIButton    *submitPhotoBut;
/** 底部图片 */
@property (weak, nonatomic) IBOutlet UIImageView *imageBottomView;
/** 重新填写按钮 */
@property (weak, nonatomic) IBOutlet UIButton    *againWriteBut;
/** 提交信息按钮 */
@property (weak, nonatomic) IBOutlet UIButton    *submitInfoBut;

@end
@implementation EMFaceStreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //创建UI
    [self makeUI];
    //创建摄像页面
    [self makeCamera];
    //创建数据
    [self makeNumber];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    //停止摄像
    [self.previewLayer.session stopRunning];
    [self.captureManager removeObserver];
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

-(void)makeNumber
{
    //张嘴数据
    number = 0;
    takePhotoNumber = 0;
    
    mouthWidthF = 0;
    mouthHeightF = 0;
    mouthWidth = 0;
    mouthHeight = 0;
    
    //摇头数据
    bigNumber = 0;
    smallNumber = 0;
    firstNumber = 0;
    
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(controlOpen) userInfo:nil repeats:YES];
    }
}
/** 定时器控制开关 */
- (void)controlOpen
{
    _isOpenPath = YES;
}

#pragma mark --- 创建UI界面
- (void)makeUI
{
    
    self.previewView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight*2/3)];
    [self.view addSubview:self.previewView];
    [self.view sendSubviewToBack:self.previewView];
    
    //提示框
    imgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 40, 100, 100)];
    [imgView setHidden:YES];
    [self.view addSubview:imgView];
    [self.view bringSubviewToFront:imgView];
    
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.text = @"请按提示做动作";
    
    //背景View
    backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-64)];
    backView.backgroundColor = [UIColor lightGrayColor];
    
    //图片放置View
    imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 10, ScreenWidth, ScreenWidth*4/3)];
    [backView addSubview:imageView];
    
    //button上传图片
    [self buttonWithTitle:@"上传图片" frame:CGRectMake(ScreenWidth/2-150, CGRectGetMaxY(imageView.frame)+10, 100, 30) action:@selector(didClickUpPhoto) AddView:backView];
    
    //重拍图片按钮
    [self buttonWithTitle:@"重拍" frame:CGRectMake(ScreenWidth/2+50, CGRectGetMaxY(imageView.frame)+10, 100, 30) action:@selector(didClickPhotoAgain) AddView:backView];

    [self.againWriteBut setHidden:YES];
    [self.submitInfoBut setHidden:YES];
}


#pragma mark --- 创建相机
-(void)makeCamera
{
    self.title = @"人脸识别";
    //adjust the UI for iOS 7
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ( IOS7_OR_LATER ){
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
#endif
    
    self.view.backgroundColor = [UIColor blackColor];
    self.previewView.backgroundColor=[UIColor clearColor];
    
    //设置初始化打开识别
//    self.faceDetector=[IFlyFaceDetector sharedInstance];
//    [self.faceDetector setParameter:@"1" forKey:@"detect"];
//    [self.faceDetector setParameter:@"1" forKey:@"align"];
    
    //初始化 CaptureSessionManager
    self.captureManager=[[CaptureManager alloc] init];
    self.captureManager.delegate=self;
    
    self.previewLayer=self.captureManager.previewLayer;
    
    self.captureManager.previewLayer.frame= self.previewView.frame;
    self.captureManager.previewLayer.position=self.previewView.center;
    
    self.captureManager.previewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    [self.previewView.layer addSublayer:self.captureManager.previewLayer];
    
    self.viewCanvas = [[CanvasView alloc] init];
    self.viewCanvas.center = self.previewView.center;
    self.viewCanvas.bounds = self.previewView.bounds;
    [self.previewView addSubview:self.viewCanvas] ;
    self.viewCanvas.center=self.captureManager.previewLayer.position;
    self.viewCanvas.backgroundColor = [UIColor clearColor];
    NSString *str = [NSString stringWithFormat:@"{{%f, %f}, {220, 240}}",(ScreenWidth-220)/2,(ScreenWidth-240)/2+15];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setObject:str forKey:@"RECT_KEY"];
    [dic setObject:@"1" forKey:@"RECT_ORI"];
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    [arr addObject:dic];
    self.viewCanvas.arrFixed = arr;
    self.viewCanvas.hidden = NO;
    
    //建立 AVCaptureStillImageOutput
    myStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *myOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [myStillImageOutput setOutputSettings:myOutputSettings];
    [self.captureManager.session addOutput:myStillImageOutput];
    
    //开始摄像
    [self.captureManager setup];
    [self.captureManager addObserver];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    [self.captureManager observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - 开启识别
- (void) showFaceLandmarksAndFaceRectWithPersonsArray:(NSMutableArray *)arrPersons
{
    if (self.viewCanvas.hidden) {
        self.viewCanvas.hidden = NO;
    }
    self.viewCanvas.arrPersons = arrPersons;
    [self.viewCanvas setNeedsDisplay] ;
}

#pragma mark --- 关闭识别
- (void) hideFace
{
    if (!self.viewCanvas.hidden) {
        self.viewCanvas.hidden = YES ;
    }
}

#pragma mark --- 脸部框识别
-(NSString*)praseDetect:(NSArray *)positionDic OrignImage:(SYFaceImage *)faceImg
{
    if(!positionDic){
        return nil;
    }
    
    // 判断摄像头方向
    BOOL isFrontCamera=self.captureManager.videoDeviceInput.device.position==AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.previewLayer.frame.size.width   / faceImg.height;
    CGFloat heightScaleBy = self.previewLayer.frame.size.height / faceImg.width;
    
    CGFloat width = [[positionDic objectAtIndex:2] floatValue];
    CGFloat height = [[positionDic objectAtIndex:3] floatValue];
    
    CGFloat top=[[positionDic objectAtIndex:1] floatValue];
    CGFloat left=[[positionDic objectAtIndex:0] floatValue];
    CGFloat right= left + width;
    CGFloat bottom = top + height;
    
    float cx = (left+right)/2;
    float cy = (top + bottom)/2;
    float w = right - left;
    float h = bottom - top;
    
    float ncx = cy ;
    float ncy = cx ;
    
    CGRect rectFace = CGRectMake(ncx-w/2 ,ncy-w/2 , w, h);
    
    if(!isFrontCamera){
        rectFace=rSwap(rectFace);
        rectFace=rRotate90(rectFace, faceImg.height, faceImg.width);
    }
    
    //判断位置
    BOOL isNotLocation = [self identifyYourFaceLeft:left right:right top:top bottom:bottom];
    
    if (isNotLocation==YES) {
        return nil;
    }
    
    NSLog(@"left=%f right=%f top=%f bottom=%f",left,right,top,bottom);
    
    _isCrossBorder = NO;
    
    rectFace=rScale(rectFace, widthScaleBy, heightScaleBy);
    
    return NSStringFromCGRect(rectFace);
}

#pragma mark --- 脸部部位识别
-(NSMutableArray*)praseAlign:(NSDictionary* )landmarkDic OrignImage:(SYFaceImage*)faceImg atFaceRectArr:(NSArray *)rectArr
{
    if(!landmarkDic){
        return nil;
    }
    
    // 判断摄像头方向
    BOOL isFrontCamera = self.captureManager.videoDeviceInput.device.position==AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy  = self.previewLayer.frame.size.width / faceImg.height;
    CGFloat heightScaleBy = self.previewLayer.frame.size.height / faceImg.width;
    
    CGFloat width  = [[rectArr objectAtIndex:2] floatValue];
    CGFloat height = [[rectArr objectAtIndex:3] floatValue];
    CGFloat top    = [[rectArr objectAtIndex:1] floatValue];
    CGFloat left   = [[rectArr objectAtIndex:0] floatValue];
    CGFloat right  = left + width;
    CGFloat bottom = top + height;
    
    NSMutableArray *arrStrPoints = [NSMutableArray array];
    NSEnumerator* keys = [landmarkDic keyEnumerator];
    for(id key in keys){
        id attr = [landmarkDic objectForKey:key];
        if(attr && [attr isKindOfClass:[NSDictionary class]]){
            
            id attr   = [landmarkDic objectForKey:key];
            CGFloat x = [[attr objectForKey:KCISYFaceResultPointX] floatValue];
            CGFloat y = [[attr objectForKey:KCISYFaceResultPointY] floatValue];
            CGPoint p = CGPointMake(x,y);
            
            if(!isFrontCamera) {
                p=pSwap(p);
                p=pRotate90(p, faceImg.height, faceImg.width);
            }
           
            //判断是否正面越界
            if (takePhotoNumber == 0) {
                [self identifyYourFaceCrossTheBorderWithLeft:left right:right
                                                         top:top bottom:bottom];
            }
            //获取嘴的坐标，判断是否张嘴
            if (takePhotoNumber == 2) {
                [self identifyYourFaceOpenMouth:key p:p];
            }
            //判断获取左侧脸
            if (takePhotoNumber == 4) {
                [self identifyYourFaceIsLeftFeceOrIsRightFace:key p:p];
            }
            //判断获取右侧脸
            if (takePhotoNumber == 6) {
                [self identifyYourFaceIsLeftFeceOrIsRightFace:key p:p];
            }
            
            p=pScale(p, widthScaleBy, heightScaleBy);
            
            [arrStrPoints addObject:NSStringFromCGPoint(p)];
            
        }
    }
    
    
    
    return arrStrPoints;
}

#pragma mark --- 脸部识别
/**
 *  使用系统自带已节省资源
 */
- (void) faceTrackRecognitionWithOrignImage:(SYFaceImage *)orignImage
{
    if (!orignImage.image) return;
    
    // 图像识别能力：可以在CIDetectorAccuracyHigh(较强的处理能力)与CIDetectorAccuracyLow(较弱的处理能力)中选择，因为想让准确度高一些在这里选择CIDetectorAccuracyHigh
    NSDictionary *opts = [NSDictionary dictionaryWithObject:
                          CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    // 将图像转换为CIImage
    CIImage *faceImage = [CIImage imageWithCGImage:orignImage.image.CGImage];
    CIDetector *faceDetector=[CIDetector detectorOfType:CIDetectorTypeFace context:nil options:opts];
    // 识别出人脸数组
    NSArray *features = [faceDetector featuresInImage:faceImage];
    NSLog(@"%ld",(long)features.count);
    if (features.count >= 1) {
        _isChange = YES;
        if (_isOpenPath == YES) {
            _isOpenPath = NO;
            [self outputFaceImageFunctionWithFaceImage:orignImage];
        }
    } else {
        _isChange = NO;
    }
   
}
/**
 *  使用阿里api确保能够精确识别人脸跟踪
 @param result
 @param faceImg
 */
-(void)praseTrackResult:(NSString*)result OrignImage:(SYFaceImage*)faceImg
{
    if(!result){
        return;
    }
    @try {
        NSError* error;
        NSData* resultData = [result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* faceDic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        resultData=nil;
        if(!faceDic){
            return;
        }
        
        NSNumber * faceRet = [faceDic objectForKey:KCISYFaceResultRet];
        NSArray  * faceArray = [faceDic objectForKey:KCISYFaceResultFace];
        NSArray  * landmarkArr = [faceDic objectForKey:KCISYFaceResultLandmark];
        faceDic=nil;
        
        int ret=0;
        if([faceRet integerValue] > 0){
            ret = [faceRet intValue];
        }
        
        //检测到人脸
        NSMutableArray *arrPersons = [NSMutableArray array] ;
        if(faceArray && [faceArray isKindOfClass:[NSArray class]]){
            
            NSString * rectString=[self praseDetect:faceArray OrignImage: faceImg];
            //整理脸部数据
            NSMutableDictionary* landmarkDic = [NSMutableDictionary dictionary];
    
            for (int i = 0; i < landmarkArr.count; i ++) {
              
                if (i == 1) {
                    NSNumber * x = landmarkArr[i-1];
                    NSNumber * y = landmarkArr[i];
                    [landmarkDic setObject:@{@"x":x,@"y":y} forKey:@"eyebrow_right_edge_right"];
                }
                if (i == 3) {
                    NSNumber * x = landmarkArr[i-1];
                    NSNumber * y = landmarkArr[i];
                    [landmarkDic setObject:@{@"x":x,@"y":y} forKey:@"eyebrow_right_edge_left"];
                }
            
                if (i == 25) {
                    NSNumber * x = landmarkArr[i-1];
                    NSNumber * y = landmarkArr[i];
                    [landmarkDic setObject:@{@"x":x,@"y":y} forKey:@"eyebrow_left_edge_right"];
                }
                if (i == 27) {
                    NSNumber * x = landmarkArr[i-1];
                    NSNumber * y = landmarkArr[i];
                    [landmarkDic setObject:@{@"x":x,@"y":y} forKey:@"eyebrow_left_edge_left"];
                }
                if (i == 165) {
                    NSNumber * x = landmarkArr[i-1];
                    NSNumber * y = landmarkArr[i];
                    [landmarkDic setObject:@{@"x":x,@"y":y} forKey:@"mouth_upper_lip_top"];
                }
                if (i == 167) {
                    NSNumber * x = landmarkArr[i-1];
                    NSNumber * y = landmarkArr[i];
                    [landmarkDic setValue:@{@"x":x,@"y":y} forKey:@"mouth_lower_lip_bottom"];
                }
            }
            NSMutableArray* strPoints=[self praseAlign:landmarkDic OrignImage:faceImg atFaceRectArr:faceArray];
            landmarkDic = nil;
            
            
            NSMutableDictionary *dicPerson = [NSMutableDictionary dictionary] ;
            if(rectString){
                [dicPerson setObject:rectString forKey:RECT_KEY];
            }
            if(strPoints){
                [dicPerson setObject:strPoints forKey:POINTS_KEY];
            }
            
            strPoints = nil;
            
            [dicPerson setObject:@"0" forKey:RECT_ORI];
            [arrPersons addObject:dicPerson] ;
            
            dicPerson = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showFaceLandmarksAndFaceRectWithPersonsArray:arrPersons];
            });
        }
        
        faceArray = nil;
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
    }
}

#pragma mark - CaptureManagerDelegate
/** 相机代理回调 */
-(void)onOutputFaceImage:(SYFaceImage*)faceImg
{
//    NSString* strResult=[self.faceDetector trackFrame:faceImg.data withWidth:faceImg.width height:faceImg.height direction:(int)faceImg.direction];
//    NSLog(@"result:%@",strResult);
   
    dispatch_async(dispatch_get_main_queue(), ^{
       [imgView setImage:[UIImage imageWithData:faceImg.data]];
    });
    
    
    if (_isChange && _isOpenPath == YES)
    {
        //关闭路径
        _isOpenPath = NO;
        [self outputFaceImageFunctionWithFaceImage:faceImg];
        
    } else {
        [self faceTrackRecognitionWithOrignImage:faceImg];
//        NSMethodSignature *sig = [self methodSignatureForSelector:@selector(faceTrackRecognitionWithOrignImage:)];
//        if (!sig) return;
//        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
//        [invocation setTarget:self];
//        [invocation setSelector:@selector(faceTrackRecognitionWithOrignImage:)];
//        [invocation setArgument:&faceImg atIndex:2];
//        [invocation retainArguments];
//        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil  waitUntilDone:NO];
    }
    
    faceImg.data = nil;
    faceImg.image = nil;
    faceImg = nil;
    
    
}

- (void)outputFaceImageFunctionWithFaceImage:(SYFaceImage*)faceImg
{
    
    
    __block SYFaceImage * staticFaceImg;
    
    [[SYFaceDetectNetwork singleton] postFaceDetecRequestNetworkWithFaceImage:faceImg atCallback:^(NSString *callback) {
        
        NSString * strResult = callback;
        //此处清理图片数据，以防止因为不必要的图片数据的反复传递造成的内存卷积占用。
        staticFaceImg.data  = nil;
        staticFaceImg.image = nil;
        
        NSMethodSignature *sig = [self methodSignatureForSelector:@selector(praseTrackResult:OrignImage:)];
        if (!sig) return;
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setTarget:self];
        [invocation setSelector:@selector(praseTrackResult:OrignImage:)];
        [invocation setArgument:&strResult atIndex:2];
        [invocation setArgument:&staticFaceImg atIndex:3];
        [invocation retainArguments];
        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil  waitUntilDone:NO];
        staticFaceImg = nil;
    }];
}


#pragma mark --- 判断位置
-(BOOL)identifyYourFaceLeft:(CGFloat)left right:(CGFloat)right top:(CGFloat)top bottom:(CGFloat)bottom
{
    //判断位置
//    if (right - left < 230 || bottom - top < 250) {
//        self.textLabel.text = @"太远了...";
//        [self delateNumber];//清数据
//        isCrossBorder = YES;
//        return YES;
//    }else if (right - left > 320 || bottom - top > 320) {
//        self.textLabel.text = @"太近了...";
//        [self delateNumber];//清数据
//        isCrossBorder = YES;
//        return YES;
//    }else{
    
    
    if (_isCameraman) {
        self.textLabel.text = @"等待倒计时拍照";
        if (takePhotoNumber == 0) {
            //正面
            takePhotoNumber = 1;
            [self timeBegin];
        } else if (takePhotoNumber == 2) {
            //张嘴
            if (_isJudgeMouth == YES) {
                takePhotoNumber = 3;
                [self timeBegin];
            }
        } else if (takePhotoNumber == 4) {
            //左侧脸
            takePhotoNumber = 5;
            [self timeBegin];
        } else if (takePhotoNumber == 6) {
            //右侧脸
            takePhotoNumber = 7;
            [self timeBegin];
        }
        return NO;
    } else {
        if (takePhotoNumber == 0) {
            //正面
            self.textLabel.text = @"请调整您的正面位置";
            return YES;
        } else if (takePhotoNumber == 2) {
            //张嘴
            self.textLabel.text = @"请调整您的张嘴动作";
            return YES;
        } else if (takePhotoNumber == 4) {
            self.textLabel.text = @"请调整您的左侧脸";
            return YES;
        } else if (takePhotoNumber == 6) {
            self.textLabel.text = @"请调整您的右侧脸";
            return YES;
        }
    }

        _isCrossBorder = NO;
//    }
    return NO;
}

#pragma mark --- 判断正脸是否越界
- (void)identifyYourFaceCrossTheBorderWithLeft:(CGFloat)left right:(CGFloat)right top:(CGFloat)top bottom:(CGFloat)bottom
{
    if (takePhotoNumber == 0 && _isSeeFace != YES)
    {
        if (left < 100 || top < 100 || right > 460 || bottom > 600)
        {
            [self delateNumber];//清数据
            takePhotoNumber = 0;
        } else {
            _isSeeFace      = YES;//完成正脸操作
            _isCameraman    = YES;//允许拍照
            [SVProgressHUD showSuccessWithStatus:@"正脸完成！！！！"];
        }
    }
}

#pragma mark --- 判断是否张嘴
-(void)identifyYourFaceOpenMouth:(NSString *)key p:(CGPoint )p
{
    if ([key isEqualToString:@"mouth_upper_lip_top"]) {
        upperY = p.y;
    }
    if ([key isEqualToString:@"mouth_lower_lip_bottom"]) {
        lowerY = p.y;
    }
  
    if (upperY && lowerY && _isJudgeMouth != YES && takePhotoNumber == 2) {
        
        number ++;
  
//      mouthWidthF = rightX - leftX < 0 ? abs(rightX - leftX) : rightX - leftX;
//      mouthHeightF = lowerY - upperY < 0 ? abs(lowerY - upperY) : lowerY - upperY;
        if (number > 500) {
            [self delateNumber];//时间过长时重新清除数据
//            [self tomAnimationWithName:@"openMouth" count:2];
        }
//        mouthWidth = rightX - leftX < 0 ? abs(rightX - leftX) : rightX - leftX;
        mouthHeight = lowerY - upperY < 0 ? abs(lowerY - upperY) : lowerY - upperY;
        NSLog(@"嘴高%d",mouthHeight);
    
        //张嘴验证完毕
        if (mouthHeight >= 40) {
            _isJudgeMouth = YES;
            imgView.animationImages = nil;
            _isCameraman = YES;
            [SVProgressHUD showSuccessWithStatus:@"张嘴完成！！！！"];
        } else {
            //验证失败
        }
        
    }
}
#pragma mark --- 判断是否是左侧脸或者右侧脸
- (void)identifyYourFaceIsLeftFeceOrIsRightFace:(NSString *)key p:(CGPoint )p
{
    if ([key isEqualToString:@"eyebrow_left_edge_left"]) {
        leftBrow_leftX = p.x;
    }
    if ([key isEqualToString:@"eyebrow_left_edge_right"]) {
        leftBrow_rightX = p.x;
    }
    if ([key isEqualToString:@"eyebrow_right_edge_left"]) {
        rightBrow_leftX = p.x;
    }
    if ([key isEqualToString:@"eyebrow_right_edge_right"]) {
        rightBrow_rightX = p.x;
    }
    number ++ ;
    if (number > 500) {
        //时间过长时重新清除数据
        [self delateNumber];
    }
    int leftBrowWidth  = leftBrow_leftX - leftBrow_rightX < 0 ? abs(leftBrow_leftX - leftBrow_rightX):leftBrow_leftX - leftBrow_rightX;
    int rightBrowWidth = rightBrow_leftX - rightBrow_rightX < 0 ? abs(rightBrow_leftX - rightBrow_rightX):rightBrow_leftX - rightBrow_rightX;
    NSLog(@"左眉毛%d----右眉毛%d",leftBrowWidth,rightBrowWidth);
    
    //判断是否取到左眉毛的坐标
    if (takePhotoNumber == 4) {
        if (leftBrow_leftX && leftBrow_rightX && rightBrow_leftX && rightBrow_rightX && _isLeftFace != YES) {
            if (leftBrowWidth > rightBrowWidth + 20) {
                _isCameraman = YES;
                _isLeftFace  = YES;
                [SVProgressHUD showSuccessWithStatus:@"左侧脸完成！！！！"];
            }
        }
    }
    //判断是否取到右眉毛的坐标
    if (takePhotoNumber == 6) {
        if (leftBrow_leftX && leftBrow_rightX && rightBrow_leftX && rightBrow_rightX && _isRightFace != YES) {
            if (rightBrowWidth > leftBrowWidth + 20) {
                _isCameraman = YES;
                _isRightFace = YES;
                [SVProgressHUD showSuccessWithStatus:@"右侧脸完成！！！！"];
            }
        }
    }
}



#pragma mark --- 判断是否摇头
-(void)identifyYourFaceShakeHead:(NSString *)key p:(CGPoint )p
{
    if ([key isEqualToString:@"mouth_middle"] && _isJudgeMouth == YES) {
        
        if (bigNumber == 0 ) {
            firstNumber = p.x;
            bigNumber = p.x;
            smallNumber = p.x;
        }else if (p.x > bigNumber) {
            bigNumber = p.x;
        }else if (p.x < smallNumber) {
            smallNumber = p.x;
        }
        //摇头验证完毕
        if (bigNumber - smallNumber > 60) {
            _isShakeHead = YES;
            [self delateNumber];//清数据
        }
    }
}

#pragma mark --- 拍照
-(void)didClickTakePhoto
{
    AVCaptureConnection *myVideoConnection = nil;
    
    //从 AVCaptureStillImageOutput 中取得正确类型的 AVCaptureConnection
    for (AVCaptureConnection *connection in myStillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                
                myVideoConnection = connection;
                break;
            }
        }
    }
    //撷取影像（包含拍照音效）
    [myStillImageOutput captureStillImageAsynchronouslyFromConnection:myVideoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        //完成撷取时的处理程序(Block)
        if (imageDataSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            
            //取得的静态影像
            UIImage *myImage = [[UIImage alloc] initWithData:imageData];
            //添加到图片数组
            [self.photoArray addObject:myImage];
            [self.submitPhotoBut setHidden:YES];
//            imageView.backgroundColor = [UIColor lightGrayColor];
//            imageView.image = myImage;
//            imageView.frame = CGRectMake(0, 10, ScreenWidth, ScreenWidth*myImage.size.height/myImage.size.width);
//            [self.view addSubview:backView];
//
            //停止摄像
            [self delateNumber];
            _isCameraman = NO;
            takePhotoNumber ++;
            if (takePhotoNumber == 8) {
                [self.previewLayer.session stopRunning];
                [self.captureManager removeObserver];
                if (_timer) {
                    [_timer invalidate];
                    _timer = nil;
                }
                self.submitPhotoBut.titleLabel.font = [UIFont systemFontOfSize:15];
                [self.submitPhotoBut setTitle:@"完成" forState:UIControlStateNormal];
                [self.submitInfoBut setHidden:NO];
                [self.againWriteBut setHidden:NO];
            }
        }
    }];
}

#pragma mark --- 重拍按钮点击事件
-(void)didClickPhotoAgain
{
    //清数据
    [self delateNumber];
    
    //开始摄像
    [self.previewLayer.session startRunning];
    self.textLabel.text = @"请调整位置...";
    
    [backView removeFromSuperview];
    
    _isSeeFace    = NO;
    _isJudgeMouth = NO;
    _isLeftFace   = NO;
    _isRightFace  = NO;
    _isShakeHead  = NO;
    
}

#pragma mark --- 上传图片按钮点击事件
-(void)didClickUpPhoto
{
    //    UIAlertView *alt = [[UIAlertView alloc]initWithTitle:@"提示" message:@"验证完成" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    //    [alt show];
    
    //上传照片失败
    //    [self.faceDelegate sendFaceImageError];
    //上传照片成功
//    [self.faceDelegate sendFaceImage:imageView.image];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 点击『验证完成』AlertView
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (imageView.image) {
        //上传照片成功
//        [self.faceDelegate sendFaceImage:imageView.image];
        //上传照片失败
//            [self.faceDelegate sendFaceImageError];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark --- 清掉对应的数
-(void)delateNumber
{
    number = 0;
    
    mouthWidthF = 0;
    mouthHeightF = 0;
    mouthWidth = 0;
    mouthHeight = 0;
    
    smallNumber = 0;
    bigNumber = 0;
    firstNumber = 0;
    
    
    
//    imgView.animationImages = nil;
//    imgView.image = [UIImage imageNamed:@"shakeHead0"];
}

#pragma mark --- 计时开始
-(void)timeBegin
{
    timeCount = 3;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
    [self.submitPhotoBut setHidden:NO];
    [self.submitPhotoBut setTitle:[NSString stringWithFormat:@"%ld",(long)timeCount] forState:UIControlStateNormal];
    self.submitPhotoBut.titleLabel.font = [UIFont systemFontOfSize:25];
    
}
#pragma mark --- 强制取消计时
- (void)cancelTimeOver
{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    [self.submitPhotoBut setHidden:YES];
    [self.submitPhotoBut setTitle:@"" forState:UIControlStateNormal];
    self.submitPhotoBut.titleLabel.font = [UIFont systemFontOfSize:25];
}

#pragma mark --- 时间变为0，拍照
- (void)timerFireMethod:(NSTimer *)theTimer
{
    timeCount --;
    if(timeCount >= 1)
    {
        [self.submitPhotoBut setTitle:[NSString stringWithFormat:@"%ld",(long)timeCount] forState:UIControlStateNormal];
    }
    else
    {
        [theTimer invalidate];
        theTimer = nil;
        
        [self didClickTakePhoto];
    }
}

#pragma mark --- 确定
- (IBAction)startPhoto:(UIButton *)sender {
    
}


#pragma mark --- 创建button公共方法
/**使用示例:[self buttonWithTitle:@"点 击" frame:CGRectMake((self.view.frame.size.width - 150)/2, (self.view.frame.size.height - 40)/3, 150, 40) action:@selector(didClickButton) AddView:self.view];*/
-(UIButton *)buttonWithTitle:(NSString *)title frame:(CGRect)frame action:(SEL)action AddView:(id)view
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    button.backgroundColor = [UIColor lightGrayColor];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchDown];
    [view addSubview:button];
    return button;
}

//#pragma mark --- UIImageView显示gif动画
//- (void)tomAnimationWithName:(NSString *)name count:(NSInteger)count
//{
//    // 如果正在动画，直接退出
//    if ([imgView isAnimating]) return;
//
//    // 动画图片的数组
//    NSMutableArray *arrayM = [NSMutableArray array];
//
//    // 添加动画播放的图片
//    for (int i = 0; i < count; i++) {
//        // 图像名称
//        NSString *imageName = [NSString stringWithFormat:@"%@%d.png", name, i];
//        //        UIImage *image = [UIImage imageNamed:imageName];
//        // ContentsOfFile需要全路径
//        NSString *path = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
//        UIImage *image = [UIImage imageWithContentsOfFile:path];
//
//        [arrayM addObject:image];
//    }
//
//    // 设置动画数组
//    imgView.animationImages = arrayM;
//    // 重复1次
//    imgView.animationRepeatCount = 100;
//    // 动画时长
//    imgView.animationDuration = imgView.animationImages.count * 0.75;
//
//    // 开始动画
//    [imgView startAnimating];
//}

#pragma mark - set/get
- (NSMutableArray *)photoArray
{
    if (!_photoArray)
    {
        _photoArray = [NSMutableArray array];
    }
    return _photoArray;
}

-(void)dealloc
{
    self.captureManager=nil;
    self.viewCanvas=nil;
    [self.previewView removeGestureRecognizer:self.tapGesture];
    self.tapGesture=nil;
}

@end

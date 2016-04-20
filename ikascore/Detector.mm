#import <Foundation/Foundation.h>
#import "ikascore-Bridging-Header.h"
#import <opencv2/opencv.hpp>

@interface Detector()
{
    cv::CascadeClassifier cascadeWin;
    cv::CascadeClassifier cascadeLose;
}
@end

@implementation Detector: NSObject

- (id)init {
    self = [super init];
    
    // 分類器の読み込み
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *pathWin = [bundle pathForResource:@"ika_result_win" ofType:@"xml"];
    NSString *pathLose = [bundle pathForResource:@"ika_result_lose" ofType:@"xml"];
    std::string cascadeNameWin = (char *)[pathWin UTF8String];
    std::string cascadeNameLose = (char *)[pathLose UTF8String];
    
    if(!cascadeWin.load(cascadeNameWin) || !cascadeLose.load(cascadeNameLose)) {
        return nil;
    }
    
    return self;
}

- (NSString *)recognizeFace:(UIImage *)image {
    // UIImage -> cv::Mat変換
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat mat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(mat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    mat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    
    std::vector<cv::Rect> res;

    // Win検出
    // 画像，出力矩形，縮小スケール，最低矩形数，（フラグ），最小矩形
    cascadeWin.detectMultiScale(mat, res,
                             1.1, 2,
                             CV_HAAR_SCALE_IMAGE,
                             cv::Size(50, 50));
    std::vector<cv::Rect>::const_iterator w = res.begin();
    if (w != res.end()) {
        return @"win";
    }
    
    // Lose検出
    cascadeLose.detectMultiScale(mat, res,
                             1.1, 2,
                             CV_HAAR_SCALE_IMAGE,
                             cv::Size(50, 50));
    std::vector<cv::Rect>::const_iterator r = res.begin();
    if (r != res.end()) {
        return @"lose";
    }
    
    return @"";
}

@end
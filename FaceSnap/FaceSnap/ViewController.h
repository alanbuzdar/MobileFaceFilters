//
//  ViewController.h
//  FaceSnap
//
//  Created by alan buzdar on 11/9/16.
//  Copyright © 2016 alan buzdar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <vector>

using namespace cv;
@interface ViewController : UIViewController<CvVideoCameraDelegate>


@property (weak, nonatomic) IBOutlet UIButton *captureHandImageButton;
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (nonatomic) CascadeClassifier classifier;
@property int display;
@property cv::Rect handRect;
@property cv::Mat hand1, hand2;
@property bool pressed;
@end


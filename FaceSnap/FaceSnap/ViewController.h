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
#import <GLKit/GLKit.h>
#import <OpenGLES/ES1/gl.h>
#include <iostream>

using namespace cv;
@interface ViewController : UIViewController<CvVideoCameraDelegate, GLKViewDelegate>


@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIButton *captureHandImageButton;
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (nonatomic) CascadeClassifier classifier;
@property int display;
@property cv::Rect handRect1, handRect2, handRect3, handRect4, handRect5;
@property cv::Mat hand1, hand2, hand3, hand4, hand5;
@property cv::Scalar mean1, mean2, mean3, mean4, mean5;
@property bool captureSkinColor;
@property EAGLContext* context;
@property (weak, nonatomic) IBOutlet GLKView *glkView;
@property GLKBaseEffect* effect;
@property GLuint viewRenderBuffer;
@property cv::Point centroid;
@property NSInteger frame;
@property int rectsize;
@property int handRectWidth;
@property int colorCount;
@property int objectType;
@property int spin;
@property int shouldSpin;
@property std::vector<float> shootingY;
@property clock_t prevTimeStamp;
@property long score;
@end


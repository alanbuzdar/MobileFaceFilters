//
//  ViewController.m
//  FaceSnap
//
//  Created by alan buzdar on 11/9/16.
//  Copyright © 2016 alan buzdar. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController
NSString* const fileName = @"haarcascade_frontalface_default";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"xml"];
    _classifier.load([filePath UTF8String]);
    
    UIImageView *imageView = (UIImageView*)[self.view viewWithTag:2];
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.rotateVideo = YES;
    [self.videoCamera start];
}


#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    int scale = 8;
    Mat grey, downSample;
    cvtColor(image, grey, CV_BGR2GRAY);
    cv::resize(grey, downSample, cv::Size(grey.cols/scale,grey.rows/scale), 0, 0);

    std::vector<cv::Rect> faces;
    cv::Rect max = cv::Rect(0,0,0,0);
    _classifier.detectMultiScale(downSample, faces, 1.1, 2, CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_SCALE_IMAGE, cv::Size(45,45));
    
    for(int i=0; i<faces.size(); i++){
        cv::Rect currentFace = faces[i];
        if(currentFace.width*currentFace.height > max.width*max.height)
            max = currentFace;
    }
    
    rectangle(image, cv::Rect(max.x*scale, max.y*scale, max.width*scale, max.height*scale),CV_RGB(255,255,0),0);


}
#endif


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

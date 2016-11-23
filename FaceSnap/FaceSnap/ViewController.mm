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
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.rotateVideo = YES;
    self.display = 0;
    [self.videoCamera start];
}

- (IBAction)changeViewButtonPressed:(id)sender {
    self.display = (self.display + 1) % 4;
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    int scale = 8;
    Mat grey, blur, output, displayImage, thresholded, largestContour;
    std::vector<std::vector<cv::Point> > contours;
    std::vector<Vec4i> hierarchy;
    RNG rng(12345);
    
    //convert image to grayscale
    cvtColor(image, grey, CV_BGR2GRAY);
    
    //blur image
    cv::GaussianBlur(grey, blur, cv::Size(35,35), 0);
    
    //threshold binary
    cv::threshold(blur, thresholded, 130, 255, THRESH_BINARY_INV);
    
    
    //find contours and hulls of each contour
    cv::findContours( thresholded, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
    std::vector<std::vector<cv::Point>> hull( contours.size() );
    for( int i = 0; i < contours.size(); i++ ) {
        convexHull( Mat(contours[i]), hull[i], false );
    }
    
    
    double area, max = 0;
    int index = 0;
    cv::Rect rect;
    
    //grab the largest contour and use that index for hull/contour displaying
    for( int i = 0; i < contours.size(); i++ )
    {
        area=contourArea(contours[i],false);
        if(area>max){
            max=area;
            index=i;
        }
    }

    drawContours( image, hull, index, Scalar(255,0,0, 1), 1, 8, std::vector<Vec4i>(), 0, cv::Point() );
    drawContours( image, contours, index, Scalar(255,255,0, 1), 2, 8, hierarchy, 0, cv::Point(0,0) );

    //later could somehow use this
//    std::vector<cv::Vec4i> defects;
//    convexityDefects(contours[index], hull[index], defects);
//    long numDefects = defects.size();
//    
//    //each defect is (start_index, end_index, farthest_pt_index, fixpt_depth);
//    cv::Point start, end, furthest;
//    double depth;
//    
//    for(int i = 0; i < numDefects; i++) {
//        start = contours.at(index).at( defects.at(i)[0]);
//        cv::circle(image, start, 5, Scalar(0,255,0,1));
//        end = contours.at(index).at( defects.at(i)[1]);
//        furthest = contours.at(index).at( defects.at(i)[2]);
//        depth = defects.at(i)[3];
//    }
    cv::cvtColor(image, image, CV_BGR2RGB);
    switch(self.display) {
        case 0:
            break;
        case 1:
            image = grey.clone();
            break;
        case 2:
            image = blur.clone();
            break;
        default:
            image = thresholded.clone();
    }
    
}
#endif


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

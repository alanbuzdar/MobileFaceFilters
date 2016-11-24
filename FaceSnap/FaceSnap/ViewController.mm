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
    cv::Rect rec;
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
    self.pressed = false;
    
    rec.x = imageView.bounds.size.width / 2 - 20;
    rec.y = imageView.bounds.size.height / 2 - 20;
    rec.width = 250;
    rec.height = 600;
    
    self.handRect = rec;
    [self.videoCamera start];
}

- (IBAction)captureHandImageButtonPressed:(id)sender {
    self.pressed = true;
}


- (IBAction)changeViewButtonPressed:(id)sender {
    self.display = (self.display + 1) % 3;
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    if(self.hand1.empty()) {
        cv::rectangle(image, self.handRect, Scalar(255,0,0,1));
        if(self.pressed) {
            printf("hand 1 ");
            self.hand1 = image(self.handRect).clone();
            self.pressed = false;
        }
    } else if(self.hand2.empty()) {
        cv::rectangle(image, self.handRect, Scalar(255,0,0,1));
        if(self.pressed) {
            printf("hand 2 ");
            self.hand2 = image(self.handRect).clone();
            self.pressed = false;
            self.captureHandImageButton.alpha = 0.0;
        }
        
        
    } else {
        Mat grey, blur, output, displayImage, thresholded, largestContour, thresh, temp;
        std::vector<std::vector<cv::Point> > contours;
        std::vector<Vec4i> hierarchy;
        
        //convert image to grayscale
//        cvtColor(image, grey, CV_BGR2GRAY);
        
        //blur image
//        cv::GaussianBlur(image, blur, cv::Size(35,35), 0);
        cv::cvtColor(image, blur, CV_RGB2HSV);

//        
//        thresh = image.clone();
//        thresh.setTo(cv::Scalar(0,0,0));
        //threshold based on skin
        cv::Scalar mean = cv::mean(self.hand1);
        cv::Scalar darker = Scalar(mean.val[0] + 60, mean.val[1] + 60, mean.val[2] + 60);
        cv::Scalar lighter = Scalar(mean.val[0] - 60, mean.val[1] - 60, mean.val[2] - 60);
        
        cv::inRange(blur, lighter, darker, thresholded);
        cv::erode(thresholded, thresholded, Mat());
        cv::dilate(thresholded, thresholded, Mat());
        thresh = thresholded.clone();
        
        //find contours and hulls of each contour
        cv::findContours( thresholded, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
        
        double area, max = 0, threshold = 10000;
        int index = 0;
        cv::Rect rect;
        
        //remove small contours
        for( int i = 0; i < contours.size(); i++ )
        {
            area=contourArea(contours[i],false);
            if(area<threshold){
                cv::drawContours(thresholded, contours, i, cv::Scalar(0), CV_FILLED, 8);
            }
        }
        
        //then go again
        cv::findContours( thresholded, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );

        std::vector<std::vector<cv::Point>> hull( contours.size() );
        for( int i = 0; i < contours.size(); i++ ) {
            convexHull( Mat(contours[i]), hull[i], false );
        }
        
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
        //    later could somehow use this
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
        
        switch(self.display) {
            case 0:
                cv::cvtColor(image, image, CV_BGR2RGB);
                break;
            case 1:
                image = blur.clone();
                break;
            default:
                image = thresh.clone();
        }
    }
}
#endif


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

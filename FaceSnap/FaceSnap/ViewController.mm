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
    self.showRects = true;
    self.captureSkinColor = false;
    self.glkView.delegate = self;
    self.effect = [GLKBaseEffect new];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    [self initializeOpenGL];
    
    cv::Rect rec1, rec2, rec3, rec4, rec5;
    rec1.x = 230;
    rec1.y = 500;
    rec1.width = 50;
    rec1.height = 50;
    
    rec2.x = 360;
    rec2.y = 500;
    rec2.width = 50;
    rec2.height = 50;
    
    rec3.x = 250;
    rec3.y = 700;
    rec3.width = 50;
    rec3.height = 50;
    
    rec4.x = 340;
    rec4.y = 700;
    rec4.width = 50;
    rec4.height = 50;
    
    rec5.x = 295;
    rec5.y = 600;
    rec5.width = 50;
    rec5.height = 50;
    
    self.handRect1 = rec1;
    self.handRect2 = rec2;
    self.handRect3 = rec3;
    self.handRect4 = rec4;
    self.handRect5 = rec5;
    [self.videoCamera start];
    
}

- (IBAction)captureHandImageButtonPressed:(id)sender {
    self.captureSkinColor = true;
}

- (IBAction)showRectanglesButtonPressed:(id)sender {
    self.showRects = !self.showRects;
}

- (IBAction)changeViewButtonPressed:(id)sender {
    self.display = (self.display + 1) % 6;
}

- (void)glkView:(GLKView *)view
     drawInRect:(CGRect)rect {
    std::cout << "\n\n\nhere\n\n\n" << std::endl;
    [self drawOpenGLObjects];
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)initializeOpenGL {
    [self createFramebuffer];

    [EAGLContext setCurrentContext: self.context];
    self.glkView.context = self.context;
    self.glkView.enableSetNeedsDisplay = true;
    self.glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
    self.glkView.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
    self.glkView.drawableMultisample = GLKViewDrawableMultisampleNone;
    [self.glkView setOpaque:NO];
    
    [self.glkView bindDrawable];
}

cv::Scalar getOffsetColor(cv::Scalar m, int r, int g, int b) {
    return cv::Scalar(m.val[0] + r, m.val[1] + g, m.val[2] + b);
}

- (void) createFramebuffer {
    GLuint viewFrameBuffer;
    glGenFramebuffers(1, &viewFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.viewRenderBuffer);
}

- (void)captureHandColor :(Mat) image {
    self.hand1 = image(self.handRect1).clone();
    self.hand2 = image(self.handRect2).clone();
    self.hand3 = image(self.handRect3).clone();
    self.hand4 = image(self.handRect4).clone();
    self.hand5 = image(self.handRect5).clone();
    
    self.mean1 = cv::mean(self.hand1);
    self.mean2 = cv::mean(self.hand2);
    self.mean3 = cv::mean(self.hand3);
    self.mean4 = cv::mean(self.hand4);
    self.mean5 = cv::mean(self.hand5);
    
    self.captureSkinColor = false;
    self.showRects = false;
}

-(void)drawOpenGLObjects
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable( GL_BLEND );
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glClearColor(1.0, 0.0, 1.0, 0.3);
    glDisable( GL_BLEND );
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    

    glMatrixMode(GL_MODELVIEW);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glEnable(GL_COLOR_MATERIAL);
    
    glLoadIdentity();
    glPushMatrix();
    
    GLfloat lightPos[] = {2.5, 3.5, -2, 1};
    glLightfv(GL_LIGHT0, GL_POSITION, lightPos);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    glPopMatrix();
}

- (void)processImage:(Mat&)image
{
    if(self.showRects) {
        cv::rectangle(image, self.handRect1, Scalar(255,0,0,1));
        cv::rectangle(image, self.handRect2, Scalar(255,0,0,1));
        cv::rectangle(image, self.handRect3, Scalar(255,0,0,1));
        cv::rectangle(image, self.handRect4, Scalar(255,0,0,1));
        cv::rectangle(image, self.handRect5, Scalar(255,0,0,1));
    }
    
    if(self.captureSkinColor) {
        [self captureHandColor :image];
    }
    if(!self.hand1.empty()) {
        Mat grey, HSV, output, displayImage, thresholded, largestContour, thresh, temp;
        Mat thresh1, thresh2, thresh3, thresh4, thresh5;
        Mat sumThresh;
        double area, max = 0;
        int index = 0, r = 50, g = 50, b = 50;
        cv::Rect rect;
        std::vector<std::vector<cv::Point>> contours;
        std::vector<Vec4i> hierarchy;
        
        cv::cvtColor(image, HSV, CV_RGB2HSV);
        cv::inRange(HSV, getOffsetColor(self.mean1, -r, -g, -b), getOffsetColor(self.mean1, r, g, b), thresh1);
        cv::inRange(HSV, getOffsetColor(self.mean2, -r, -g, -b), getOffsetColor(self.mean2, r, g, b), thresh2);
        cv::inRange(HSV, getOffsetColor(self.mean3, -r, -g, -b), getOffsetColor(self.mean3, r, g, b), thresh3);
        cv::inRange(HSV, getOffsetColor(self.mean4, -r, -g, -b), getOffsetColor(self.mean4, r, g, b), thresh4);
        cv::inRange(HSV, getOffsetColor(self.mean5, -r, -g, -b), getOffsetColor(self.mean5, r, g, b), thresh5);
        
        cv::add(thresh1, thresh2, sumThresh);
        cv::add(sumThresh, thresh3, sumThresh);
        cv::add(sumThresh, thresh4, sumThresh);
        cv::add(sumThresh, thresh5, sumThresh);
        
        
        cv::medianBlur(sumThresh, sumThresh, 5);
        cv::erode(sumThresh, sumThresh, Mat());
        output = sumThresh.clone();
        
//        find contours and hulls of each contour
        cv::findContours( output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );

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
        [self.glkView display];
//
        
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
                image = sumThresh.clone();
                break;
            case 2:
                image = thresh1.clone();
                break;
            case 3:
                image = thresh2.clone();
                break;
            case 4:
                image = thresh3.clone();
                break;
            case 5:
                image = thresh4.clone();
                break;
            default:
                image = thresh5.clone();
        }
    }
}
#endif


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

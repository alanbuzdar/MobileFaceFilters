//
//  ViewController.m
//  FaceSnap
//
//  Created by alan buzdar on 11/9/16.
//  Copyright © 2016 alan buzdar. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES1/gl.h>
#include<cstdlib>
#include<cstdio>
#include<iostream>

#define DEGREES_TO_RADIANS(x) (3.14159265358979323846 * x / 180.0)

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
    self.frame = 0;
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
    _rectsize = 20;
    
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
    cv::cvtColor(image, image, CV_RGB2HSV);
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


-(void)drawObject
{
    glColor4f(1, 1, 1, 1);
    GLfloat vertices[720];
    GLfloat upnormals[360*3];
    GLfloat downnormals[360*3];
    float x_amount = 0.25;
    float y_amount = x_amount * self.view.bounds.size.width / self.view.bounds.size.height;
    float length = 0.25;
    std::cout << y_amount << std::endl;
    for (int i = 0; i < 720; i += 2) {
        vertices[i]   = (GLfloat)(cos(DEGREES_TO_RADIANS(-i/2)) * x_amount);
        vertices[i+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(-i/2)) * y_amount);
        
        upnormals[i/2*3] = 0;
        upnormals[i/2*3+1] = 0;
        upnormals[i/2*3+2] = -1;
        
        downnormals[i/2*3] = 0;
        downnormals[i/2*3+1] = 0;
        downnormals[i/2*3+2] = 1;
    }
    glColor4f(1, 1, 0, 1);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, downnormals);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 360);
    glTranslatef(0, 0, -length);
    glNormalPointer(GL_FLOAT, 0, upnormals);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 360);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    
    glTranslatef(0, 0, length);
    GLfloat sides[361 * 2 * 3];
    GLfloat normals[361 * 2 * 3];
    for (int i = 0; i <= 360; i++) {
        sides[i*6]   = (GLfloat)(cos(DEGREES_TO_RADIANS(i)) * x_amount);
        sides[i*6+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(i)) * y_amount);
        sides[i*6+2] = 0;
        
        sides[i*6+3]   = (GLfloat)(cos(DEGREES_TO_RADIANS(i)) * x_amount);
        sides[i*6+4] = (GLfloat)(sin(DEGREES_TO_RADIANS(i)) * y_amount);
        sides[i*6+5] = -length;
        
        normals[i*6] = (GLfloat)cos(DEGREES_TO_RADIANS(i));
        normals[i*6+1] = (GLfloat)sin(DEGREES_TO_RADIANS(i));
        normals[i*6+2] = 0;
        
        normals[i*6+3] = (GLfloat)cos(DEGREES_TO_RADIANS(i));
        normals[i*6+4] = (GLfloat)sin(DEGREES_TO_RADIANS(i));
        normals[i*6+5] = 0;
    }
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, sides);
    glNormalPointer(GL_FLOAT, 0, normals);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 361*2);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
}

- (void) drawAxes:(float) length
{
    GLfloat vertice[] = {0,0,0,length,0,0};
    glDisable(GL_LIGHTING);
    //x
    glColor4f(1, 0, 0, 1);
    glEnableClientState(GL_VERTEX_ARRAY) ;
    glVertexPointer(3, GL_FLOAT, 0, vertice);
    glLineWidth(5);
    glDrawArrays(GL_LINES, 0, 3);
    glDisableClientState(GL_VERTEX_ARRAY);
    
    //y
    glColor4f(0, 1, 0, 1);
    vertice[3] = 0; vertice[4] = length;
    glEnableClientState(GL_VERTEX_ARRAY) ;
    glVertexPointer(3, GL_FLOAT, 0, vertice);
    glLineWidth(5);
    glDrawArrays(GL_LINES, 0, 3);
    glDisableClientState(GL_VERTEX_ARRAY);
    
    //z
    glColor4f(0, 0, 1, 1);
    vertice[4] = 0; vertice[5] = length;
    glEnableClientState(GL_VERTEX_ARRAY) ;
    glVertexPointer(3, GL_FLOAT, 0, vertice);
    glLineWidth(5);
    glDrawArrays(GL_LINES, 0, 3);
    glDisableClientState(GL_VERTEX_ARRAY);
}

-(float)getZCoordinate
{
    float z = 2.0;//max(1.0, 1.0);
    
    return z;
}

-(void)drawOpenGLObjects
{
    GLfloat near = 1.0f, far = 100.0f;
    float normalizedX = _centroid.x / self.view.bounds.size.width - 1;
    float normalizedY = _centroid.y / self.view.bounds.size.height - 1;
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable( GL_BLEND );
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    //    glClearColor(1.0, 0.0, 1.0, 0.3);
    glDisable( GL_BLEND );
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glFrustumf(-1, 1, -1, 1, near, far);

    
    glMatrixMode(GL_MODELVIEW);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glEnable(GL_COLOR_MATERIAL);
    glLoadIdentity();
    glPushMatrix();
    
    cv::Mat RotMat = cv::Mat::zeros(4, 4, CV_32F);
    RotMat.at<float>(0,0) = 1.0f;
    RotMat.at<float>(1,1) = -1.0f;
    RotMat.at<float>(2,2) = -1.0f;
    RotMat.at<float>(3,3) = 1.0f;
    
    
    glLoadMatrixf(&RotMat.at<float>(0,0));
    float z = [self getZCoordinate];
    glTranslatef(normalizedX * z, normalizedY * z, z);
    GLfloat lightPos[] = {0, 0, -4, 1};
    glLightfv(GL_LIGHT0, GL_POSITION, lightPos);
    
    
    [self drawAxes:1.0];
    [self drawObject];
    
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    glPopMatrix();
}


- (void)updateHandColor: (Mat) image {
    if(_centroid.x < 50 || _centroid.x > image.cols-50 || _centroid.y < 50 || _centroid.y > image.rows-50)
        return;
    cv::cvtColor(image, image, CV_RGB2HSV);
    self.handRect1 = cv::Rect(_centroid.x-50, _centroid.y-50, _rectsize, _rectsize);
    self.handRect2 = cv::Rect(_centroid.x+50-_rectsize, _centroid.y-50, _rectsize, _rectsize);
    self.handRect3 = cv::Rect(_centroid.x, _centroid.y, _rectsize, _rectsize);
    self.handRect4 = cv::Rect(_centroid.x+50-_rectsize, _centroid.y+50-_rectsize, _rectsize, _rectsize);
    self.handRect5 = cv::Rect(_centroid.x-50, _centroid.y+50-_rectsize, _rectsize, _rectsize);

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
    
}

- (void)processImage:(Mat&)image;

{
    if(self.captureSkinColor) {
        [self captureHandColor :image];
    }
    if(!self.hand1.empty()) {
        Mat grey, HSV, output, displayImage, thresholded, largestContour, thresh, temp;
        Mat thresh1, thresh2, thresh3, thresh4, thresh5;
        Mat sumThresh;
        double area, max = 0;
        int index = 0, h = 10, s = 25, v = 50;
        cv::Rect rect;
        std::vector<std::vector<cv::Point>> contours;
        std::vector<Vec4i> hierarchy;
        _frame++;
        if(_frame % 5 == 0 ){
            _frame = 1;
            [self updateHandColor:image];
        }
        cv::cvtColor(image, HSV, CV_RGB2HSV);
        cv::inRange(HSV, getOffsetColor(self.mean1, -h, -s, -v), getOffsetColor(self.mean1, h, s, v), thresh1);
        cv::inRange(HSV, getOffsetColor(self.mean2, -h, -s, -v), getOffsetColor(self.mean2, h, s, v), thresh2);
        cv::inRange(HSV, getOffsetColor(self.mean3, -h, -s, -v), getOffsetColor(self.mean3, h, s, v), thresh3);
        cv::inRange(HSV, getOffsetColor(self.mean4, -h, -s, -v), getOffsetColor(self.mean4, h, s, v), thresh4);
        cv::inRange(HSV, getOffsetColor(self.mean5, -h, -s, -v), getOffsetColor(self.mean5, h, s, v), thresh5);
        
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
        
        if(hull.size() > index){
            Moments m = moments(hull[index]);
            _centroid = cv::Point(m.m10/m.m00, m.m01/m.m00);
         }
        
        drawContours( image, hull, index, Scalar(255,0,0, 1), 1, 8, std::vector<Vec4i>(), 0, cv::Point() );
        drawContours( image, contours, index, Scalar(255,255,0, 1), 2, 8, hierarchy, 0, cv::Point(0,0) );
        
        
        cv::Rect handBoundingRect = boundingRect(contours[index]);
        cv::Rect newHandBoundingRect;
        int rectW = handBoundingRect.width;
        int rectH = handBoundingRect.height;
        float goldenRatio = 1.3333;// h/w
        int maxHeight = rectW*goldenRatio;
        if(rectH > maxHeight){
            newHandBoundingRect = cv::Rect(handBoundingRect.tl().x, handBoundingRect.tl().y, rectW, maxHeight);
        }else{
            newHandBoundingRect = handBoundingRect;
        }
        
        cv::rectangle(image, newHandBoundingRect, Scalar(0,255,0, 1));
        
        
        [self.glkView display];
//

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
    if(self.showRects) {
        cv::rectangle(image, self.handRect1, Scalar(0,0,255,1));
        cv::rectangle(image, self.handRect2, Scalar(0,0,255,1));
        cv::rectangle(image, self.handRect3, Scalar(0,0,255,1));
        cv::rectangle(image, self.handRect4, Scalar(0,0,255,1));
        cv::rectangle(image, self.handRect5, Scalar(0,0,255,1));
    }
}
#endif


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

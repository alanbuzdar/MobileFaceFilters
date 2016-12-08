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
    self.captureSkinColor = false;
    self.glkView.delegate = self;
    self.effect = [GLKBaseEffect new];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    self.frame = 0;
    self.colorCount = 0;
    self.prevTimeStamp = 0;
    self.objectType = 0;
    self.shouldSpin = 0;
    self.spin = 0;

    [self initializeOpenGL];
    
    cv::Rect rec1, rec2, rec3, rec4, rec5;
    rec1.x = 250;
    rec1.y = 500;
    rec1.width = 30;
    rec1.height = 30;
    
    rec2.x = 340;
    rec2.y = 500;
    rec2.width = 30;
    rec2.height = 30;
    
    rec3.x = 250;
    rec3.y = 600;
    rec3.width = 30;
    rec3.height = 30;
    
    rec4.x = 320;
    rec4.y = 600;
    rec4.width = 30;
    rec4.height = 30;
    
    rec5.x = 295;
    rec5.y = 550;
    rec5.width = 30;
    rec5.height = 30;
    
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

- (IBAction)changeViewButtonPressed:(id)sender {
    self.display = (self.display + 1) % 7;
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
}

-(void)drawCylinder {
    glEnable(GL_LIGHTING);

    GLfloat vertices[720];
    GLfloat upnormals[360*3];
    GLfloat downnormals[360*3];
    float x_amount = 0.8;
    float y_amount = self.view.bounds.size.width / self.view.bounds.size.height;
    float length = 0.5;

    for (int i = 0; i < 720; i += 2) {
        
        vertices[i]   = (GLfloat)(cos(DEGREES_TO_RADIANS(-i/2)) * x_amount);
        vertices[i+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(-i/2)) * y_amount);

        
        upnormals[i/2*3] = 0;
        upnormals[i/2*3+1] = 0;
        upnormals[i/2*3+2] = -1;//-cos(DEGREES_TO_RADIANS(_spin));
        
        downnormals[i/2*3] = 0;
        downnormals[i/2*3+1] = 0;
        downnormals[i/2*3+2] = 1;//cos(DEGREES_TO_RADIANS(_spin));
    }
    
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
}

-(void)drawObject
{
    cv::Scalar color;
    switch(self.colorCount) {
        case 0:
            glColor4f(1, 1, 0, 1);
            break;
        case 1:
            glColor4f(1, 0, 1, 1);
            break;
        case 2:
            glColor4f(0, 1, 1, 1);
            break;
    }
    if(self.shouldSpin) {
       glRotatef(self.spin, 0, 0, 1);
    }
    

    switch(self.objectType) {
        case 0:
            [self drawCylinder];
        break;
        case 1:
            break;
            
    }
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
    float handPercent = self.handRectWidth / (self.view.bounds.size.width * .05) - 1;
    
    handPercent = 10.0 - handPercent;
    float scale = handPercent;
    return 2.0 + scale;
}

-(void)drawOpenGLObjects
{
    GLfloat near = 1.0f, far = 100.0f;
    float normalizedX = _centroid.x / self.view.bounds.size.width - 1;
    float normalizedY = _centroid.y / self.view.bounds.size.height - 1;
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable( GL_BLEND );
    glEnable( GL_DEPTH_TEST );
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
    
    glRotatef(-40, 1, 0, 0);
    GLfloat lightPos[] = {0, 1.0, -3, 1};
    glLightfv(GL_LIGHT0, GL_POSITION, lightPos);
    
//    [self drawAxes:1.0];
    [self drawObject];
    glDisable(GL_LIGHTING);
    
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

float vertexAngle(cv::Point p1, cv::Point p2, cv::Point p3){
    // return angle at p2
    float angle;
    float d12, d23, d13;
    d12 = dist(p1, p2);
    d23 = dist(p2, p3);
    d13 = dist(p1, p3);
    
    float ratio = ( (d23*d23)+(d12*d12)-(d13*d13) )/( 2*d12*d23 );
    angle = acos(ratio);
    angle = angle*180/M_PI;
    return angle;
}

float dist(cv::Point p1, cv::Point p2){
  return sqrt((p1.x-p2.x)*(p1.x-p2.x) + (p1.y-p2.y)*(p1.y-p2.y));
}

- (void)processImage:(Mat&)image {
    _spin = (_spin + 20) % 360;
    if(self.captureSkinColor) {
        [self captureHandColor :image];
    }
    if(!self.hand1.empty()) {
        Mat grey, HSV, output, displayImage, thresholded, largestContour, thresh, temp;
        Mat thresh1, thresh2, thresh3, thresh4, thresh5;
        Mat image_clone = image.clone();
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
        std::vector<std::vector<int>> hullI(contours.size());

        for( int i = 0; i < contours.size(); i++ ) {
            convexHull( Mat(contours[i]), hull[i], false );
            convexHull( Mat(contours[i]), hullI[i], false );
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
        
        std::vector<Vec4i> defects;
        std::vector<Vec4i> fingers;
        if(hull.size() > index && hull[index].size() > 2 && contours[index].size() > 2){
            cv::Rect handBoundingRect = boundingRect(contours[index]);
            cv::Rect newHandBoundingRect;
            int rectW = handBoundingRect.width;
            int rectH = handBoundingRect.height;
            float goldenRatio = 1.1;// h/w
            int maxHeight = rectW*goldenRatio;
            if(rectH > maxHeight){
                newHandBoundingRect = cv::Rect(handBoundingRect.tl().x, handBoundingRect.tl().y, rectW, maxHeight);
            }else{
                newHandBoundingRect = handBoundingRect;
            }
            
            
//            _centroid = cv::Point(newHandBoundingRect.x+newHandBoundingRect.width/2, newHandBoundingRect.y+newHandBoundingRect.height/2+newHandBoundingRect.height/10);
            convexityDefects(contours[index], hullI[index], defects);
            for(int i=0; i < defects.size(); i++){
                Vec4i current = defects[i];
                cv::Point point1 = contours[index][current[0]];
                cv::Point point2 = contours[index][current[2]];
                cv::Point point3 = contours[index][current[1]];
                
                float angle = vertexAngle( point1,  point2,  point3);
                float d12 = dist(point1, point2);
                float d23 = dist(point2, point3);
                if(angle < 90 && d12 < 1280/3 && d23 < 1280/3 && d12 > 128 && d23 > 128){
                    fingers.push_back(current);
                }

            }
            
            for(int j=0; j<fingers.size(); j++){
                cv::circle(image, contours[index][fingers[j][0]], 50, Scalar(0,0,255, 1), -1);
            }
            
            
            if(_frame % 2 == 0){
            
                cv::Point center;
                double dist, maxdist = -1;
                std::vector<cv::Point> contours_copy = contours[index];
                int factor = 3;
                
                
                for(int i = 0; i < contours_copy.size(); i++) {
                    contours_copy.at(i) /= factor;
                }
                
                cv::Mat image_copy;
                resize(image, image_copy, cv::Size(image.size().width/factor, image.size().height/factor));
                
                
                for(int i = 0;i < image_copy.cols;i+=10)
                {
                    for(int j = 0;j < image_copy.rows;j+=10)
                    {
                        
                        dist = pointPolygonTest(contours_copy, cv::Point(i,j),true);
                        if(dist > maxdist)
                        {
                            maxdist = dist;
                            center = cv::Point(i,j);
                        }
                    }
                }
                cv::Point center_copy;
        
                center_copy.x = center.x*factor;
                center_copy.y = center.y*factor;
                _centroid = center_copy;
                if(maxdist > 0) {
                    self.handRectWidth = maxdist*factor;
                    cv::circle(image, center_copy, self.handRectWidth, cv::Scalar(220,75,20),1,CV_AA);
                }
            }
            
        }

        drawContours( image, hull, index, Scalar(255,0,0, 1), 1, 8, std::vector<Vec4i>(), 0, cv::Point() );
        drawContours( image, contours, index, Scalar(255,255,0, 1), 2, 8, hierarchy, 0, cv::Point(0,0) );
        
        if(fingers.size() >= 3){
            [self.glkView display];
        } else if (fingers.size() == 2 && (clock() - self.prevTimeStamp > 250*1e-3*CLOCKS_PER_SEC)) {
            self.colorCount = (self.colorCount + 1) % 3;
            self.prevTimeStamp = clock();
        } else if (fingers.size() <= 1 && (clock() - self.prevTimeStamp > 250*1e-3*CLOCKS_PER_SEC)) {
//            self.objectType = (self.objectType + 1) % 2;
            self.shouldSpin = (self.shouldSpin + 1) % 2;
            self.prevTimeStamp = clock();
        }
        else {
            glClear(GL_COLOR_BUFFER_BIT);
            [self.context presentRenderbuffer:GL_RENDERBUFFER];
        }
        
        cv::rectangle(image, self.handRect1, Scalar(0,0,255,1));
        cv::rectangle(image, self.handRect2, Scalar(0,0,255,1));
        cv::rectangle(image, self.handRect3, Scalar(0,0,255,1));
        cv::rectangle(image, self.handRect4, Scalar(0,0,255,1));
        cv::rectangle(image, self.handRect5, Scalar(0,0,255,1));
        
        switch(self.display) {
            case 0:
                cv::cvtColor(image_clone, image, CV_BGR2RGB);
                break;
            case 1:
                cv::cvtColor(image, image, CV_BGR2RGB);
                break;
            case 2:
                image = sumThresh.clone();
                break;
            case 3:
                image = thresh1.clone();
                break;
            case 4:
                image = thresh2.clone();
                break;
            case 5:
                image = thresh3.clone();
                break;
            case 6:
                image = thresh4.clone();
                break;
            default:
                image = thresh5.clone();
        }
    } else {
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

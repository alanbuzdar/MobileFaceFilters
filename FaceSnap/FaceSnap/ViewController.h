//
//  ViewController.h
//  FaceSnap
//
//  Created by alan buzdar on 11/9/16.
//  Copyright © 2016 alan buzdar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
using namespace cv;

@interface ViewController : UIViewController<CvVideoCameraDelegate>
    {
        CvVideoCamera* videoCamera;
    }
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@end


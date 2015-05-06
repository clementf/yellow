//
//  ImageProcessFactory.m
//  yellow
//
//  Created by Boris Moriniere on 02/03/2015.
//  Copyright (c) 2015 isen. All rights reserved.
//


#import "ImageProcessFactory.h"

#import "opencv2/opencv.hpp"
using namespace cv;
using namespace std;

@implementation ImageProcessFactory

- (Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


- (Mat) crop:(Mat)pickedImage pointCoords:(NSArray *) points{
    Mat src= pickedImage;
    vector<Point2f> corners;
    for(int i=0;i<8;i++){
        float x=(float)[[points objectAtIndex:i++] intValue];
        float y=(float)[[points objectAtIndex:i] intValue];
        Point2f pt=Point2f(x,y);
        corners.push_back(pt);
    }
    
    cv::Rect contour=boundingRect(corners);
    src=src(contour);
    vector<vector<cv::Point> > c;
    vector<cv::Point> v;
    for (int i=0;i<corners.size();i++){
        v.push_back(cv::Point(corners[i].x-contour.x,corners[i].y-contour.y));
    }
    c.push_back(v);
    
    Mat mask = Mat::zeros(src.rows, src.cols, CV_8UC1);
    drawContours(mask, c, -1, Scalar(255), -1);
    
    Mat crop(src.rows, src.cols, CV_8UC3);
    crop.setTo(Scalar(0,0,0));
    src.copyTo(crop, mask);
    
    return crop;
}

- (Mat) detectBalls:(Mat)src{
    Mat seuil, blurred;
    vector<Mat> channels(3);
    GaussianBlur( src, blurred, cv::Size(21,21), 0, 0, BORDER_DEFAULT );
    
    split(blurred, channels);
    Scalar tempVal = mean( channels[2] );
    double m = tempVal.val[0];
    double min, max;
    minMaxLoc(channels[2], &min, &max);
    //Magic Boris
    int s=(3*max+m)/4;
    
    threshold(channels[2], seuil, s, 255, THRESH_BINARY);
    
    vector<vector<cv::Point> > reflects;
    findContours(seuil, reflects, RETR_EXTERNAL, CHAIN_APPROX_NONE);
    vector<Mat> subMats;
    if(reflects.size()>0){
        for(int i=0;i<reflects.size();i++){
            cv::Rect box=boundingRect(reflects[i]);
            circle( src, cv::Point(box.x+box.width/2, box.y+box.height/2), 3, Scalar(0,255,0), -1, 4, 0 );
        }
    }
    
    return src;

}

- (Mat) detectPig:(Mat)src{
    Mat HSV, imgGray, blurred;
    cv::GaussianBlur( src, blurred, cv::Size(17,17), 0, 0, BORDER_DEFAULT );
    
    //Find the cochon
    cv::cvtColor(blurred,HSV,COLOR_RGB2HSV);
    inRange(HSV,cv::Scalar(0,90,60),cv::Scalar(30,255,255),imgGray);
    vector<Vec3f> pigs;
    HoughCircles( imgGray, pigs, HOUGH_GRADIENT, 1, 100, 5, 10, 3, 12 );
    
    // Draw the circle around the cochon
    for( size_t i = 0; i < pigs.size(); i++ ){
        cv::Point center(cvRound(pigs[i][0]), cvRound(pigs[i][1]));
        int radius = cvRound(pigs[i][2]);
        cv::circle( src, center, 3, Scalar(0,255,0), -1, 4, 0 );
        // circle outline
        cv::circle( src, center, radius, Scalar(0,0,255), 1, 3, 0 );
    }
    
    return src;
    
}

- (UIImage *) detection:(UIImage *)pickedImage pointCoords:(NSArray *) points{
    Mat src, imgCropped, imgWithBalls, finalImg;
    
    src = [self cvMatFromUIImage:pickedImage];
    //Crop the image with the points given by the user
    imgCropped = [self crop:src pointCoords:points];
    //Detect the balls using reflects
    imgWithBalls = [self detectBalls:imgCropped];
    //detect the pig
    finalImg = [self detectPig:imgWithBalls];
    
    return [self UIImageFromCVMat:finalImg];
}


@end
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

- (UIImage *) blurImage:(UIImage *)pickedImage{
    Mat cvPickedImg=[self cvMatFromUIImage:pickedImage];
    resize(cvPickedImg, cvPickedImg, cv::Size(cvPickedImg.cols/4, cvPickedImg.rows/4));
    return [self UIImageFromCVMat:cvPickedImg];
}


- (UIImage *) transformPerspective:(UIImage *)pickedImage pointCoords:(NSArray *) points{
    //    vector<cv::Point2f> quad_pts;
    //    vector<Point2f> corners;
    //    float reduction = 1.0f / scaling;
    //    int i = 0;
    //    int size = 400;
    //
    //    for (i = 0; i < 8; i+=2){
    //        Point2f pt = Point2f(points[i]*reduction, points[i+1]*reduction);
    //        corners.push_back(pt);
    //    }
    //    quad_pts.push_back(Point2f(0, 0));
    //    quad_pts.push_back(Point2f(size, 0));
    //    quad_pts.push_back(Point2f(size, size));
    //    quad_pts.push_back(Point2f(0, size));
    //
    //    Mat transmtx = getPerspectiveTransform(corners, quad_pts);
    //    for (int i = 0; i < 2; i++)
    //    {
    //        for (int j = 0; j < 2; j++)
    //        {
    //            cout << transmtx.at<unsigned char>(i,j) << endl;
    //
    //        }
    //    }
    //
    Mat src=[self cvMatFromUIImage:pickedImage];
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
    
    return [self UIImageFromCVMat:crop];
}

- (UIImage *) detection:(UIImage *)pickedImage pointCoords:(NSArray *) points{
    //[self UIImageFromCVMat:cvPickedImg];
    UIImage *imgSrc = [self transformPerspective:pickedImage pointCoords:points];
    Mat src = [self cvMatFromUIImage:imgSrc];
    
    Mat seuil, blurred;
    vector<Mat> channel(3);
    GaussianBlur( src, blurred, cv::Size(21,21), 0, 0, BORDER_DEFAULT );
    //blur( src, src, Size(15,15));
    
    split(blurred, channel);
    Scalar tempVal = mean( channel[2] );
    double m = tempVal.val[0];
    double min, max;
    minMaxLoc(channel[2], &min, &max);
    int s=(3*max+m)/4;

    
    threshold(channel[2], seuil, s, 255, THRESH_BINARY);
    
    vector<vector<cv::Point> > reflets;
    findContours(seuil, reflets, RETR_EXTERNAL, CHAIN_APPROX_NONE);
    vector<Mat> subMats;
    if(reflets.size()>0){
        NSLog(@"reflets : %lu", reflets.size());
        for(int i=0;i<reflets.size();i++){
            cv::Rect box=boundingRect(reflets[i]);
            circle( src, cv::Point(box.x+box.width/2, box.y+box.height/2), 3, Scalar(0,255,0), -1, 4, 0 );
        }
    }
    
    Mat HSV, imgGray;
    cv::GaussianBlur( src, blurred, cv::Size(17,17), 0, 0, BORDER_DEFAULT );
    
    //Find the cochon
    
    cv::cvtColor(blurred,HSV,COLOR_RGB2HSV);
    inRange(HSV,cv::Scalar(0,90,60),cv::Scalar(30,255,255),imgGray);
    vector<Vec3f> pigs;
    HoughCircles( imgGray, pigs, HOUGH_GRADIENT, 1, 100, 5, 10, 3, 12 );
    
    /// Draw the circles detected
    for( size_t i = 0; i < pigs.size(); i++ ){
        cv::Point center(cvRound(pigs[i][0]), cvRound(pigs[i][1]));
        int radius = cvRound(pigs[i][2]);
        cv::circle( src, center, 3, Scalar(0,255,0), -1, 4, 0 );
        // circle outline
        cv::circle( src, center, radius, Scalar(0,0,255), 1, 3, 0 );
        NSLog(@"pig detected");
    }
    //imshow("with circles and the cochon", src);
    
    return [self UIImageFromCVMat:src];
}


@end
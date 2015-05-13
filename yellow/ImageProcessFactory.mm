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

cv::Point2f pig;
std::vector<cv::Point2f> balls;
cv::Mat transmtx;
cv::Mat backTransmtx;
int size=4000;
int m = 0;

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

- (vector<Point2f>) detectMarkers:(Mat)src{
    vector<Point2f> points;
    Mat blurred, HSV, imgGray;
    vector<Mat> channels;
    
    //H : 25 -> 35
    //S : > 100
    //V : > 100
    cv::GaussianBlur( src, blurred, cv::Size(17,17), 0, 0, BORDER_DEFAULT );
    
    //Find the cochon
    cv::cvtColor(blurred,HSV,COLOR_RGB2HSV);
    
    imgGray = Mat::zeros(HSV.rows, HSV.cols, CV_8UC1);
    split(HSV, channels);
    for(int j=0; j<HSV.rows; j++){
        for(int k=0; k<HSV.cols; k++) {
            if((channels[0].at<unsigned char>(j,k) > 25 || channels[0].at<unsigned char>(j,k) < 35) &&
               channels[1].at<unsigned char>(j,k) > 100 &&
               channels[2].at<unsigned char>(j,k) > 100){
                imgGray.at<unsigned char>(j, k) = 255;
            }
        }
    }
    
    vector<vector<cv::Point> > balls;
    findContours(imgGray, balls, RETR_EXTERNAL, CHAIN_APPROX_NONE);
    NSLog(@"balls tennis %lu", balls.size());
    // Check different contour and verify approximative square box around contour
    if(balls.size()>0){
        for(int i=0;i<balls.size();i++){
            cv::Rect box=boundingRect(balls[i]);
            rectangle(src, box, Scalar(0,255,0), 2);
                cv::Point center(box.x+box.width/2, box.y+box.height/2);
//                int radius=(box.width+box.height)/4;
//                cv::circle( src, center, 3, Scalar(0,255,0), -1, 4, 0 );
//                cv::circle( src, center, radius, Scalar(0,0,255), 1, 3, 0 );
            NSLog(@"Box height %d" , box.height);
            NSLog(@"Box width %d" , box.width);
            pig=Point2f(center.x ,center.y);
            if(box.width > 23 && box.height > 23)
                points.push_back(pig);
            
        }
    }

    
    return points;
}

- (vector<Mat>) crop:(Mat)pickedImage pointCoords:(vector<Point2f>) corners{
    Mat src= pickedImage;
//   vector<Point2f> corners;
//    for(int i=0;i<8;i++){
//        float x=(float)[[points objectAtIndex:i++] intValue];
//        float y=(float)[[points objectAtIndex:i] intValue];
//        Point2f pt=Point2f(x,y);
//        corners.push_back(pt);
//    }
    
    cv::Rect contour=boundingRect(corners);
    src=src(contour);
    vector<vector<cv::Point> > c;
    vector<cv::Point> v;
    for (int i=0;i<corners.size();i++){
        corners[i].x-=contour.x;
        corners[i].y-=contour.y;
        v.push_back(cv::Point(corners[i].x,corners[i].y));
    }
    c.push_back(v);
    
    Mat mask = Mat::zeros(src.rows, src.cols, CV_8UC1);
    drawContours(mask, c, -1, Scalar(255), -1);
    
    Mat crop(src.rows, src.cols, CV_8UC3);
    crop.setTo(Scalar(0,0,0));
    src.copyTo(crop, mask);
    
    std::vector<cv::Point2f> quad_pts;
    quad_pts.push_back(Point2f(0, 0));
    quad_pts.push_back(Point2f(size, 0));
    quad_pts.push_back(Point2f(size, size));
    quad_pts.push_back(Point2f(0, size));
    transmtx = getPerspectiveTransform(corners, quad_pts);
    backTransmtx=getPerspectiveTransform(quad_pts, corners);
    vector<Mat> toRet;
    toRet.push_back(crop);
    toRet.push_back(mask);
    return toRet;
}

- (Mat) detectBalls:(vector<Mat>)inputs{
    Mat seuil, blurred, src, mask, dst;
    src = inputs.at(0);
    dst=src.clone();
    mask = inputs.at(1);
    vector<Mat> channels(3);
    GaussianBlur( src, blurred, cv::Size(21,21), 0, 0, BORDER_DEFAULT );
    
    split(blurred, channels);
    Scalar tempVal = mean( channels[2], mask );
    m = tempVal.val[0];
    double min, max;
    minMaxLoc(channels[2], &min, &max);
    //Magic Boris
    int s = (2*max+m)/3;
    threshold(channels[2], seuil, s, 255, THRESH_BINARY);
    
    vector<vector<cv::Point> > reflects;
    findContours(seuil, reflects, RETR_EXTERNAL, CHAIN_APPROX_NONE);
    
    vector<Mat> subMats;
    split(src, channels);
    if(reflects.size()>0){
        for(int i=0;i<reflects.size();i++){
            cv::Rect box=boundingRect(reflects[i]);
            cv::Point center=Point2f(box.x+(box.width/2), box.y+(box.height)/2);
            double ti=transmtx.at<double>(2,0)*center.x+transmtx.at<double>(2,1)*center.y+transmtx.at<double>(2,2);
            cv::Point realCenter=cv::Point((transmtx.at<double>(0,0)*center.x+transmtx.at<double>(0,1)*center.y+transmtx.at<double>(0,2))/ti,
                                           (transmtx.at<double>(1,0)*center.x+transmtx.at<double>(1,1)*center.y+transmtx.at<double>(1,2))/ti);
            cv::Point realTopLeft=cv::Point(realCenter.x-40, realCenter.y);
            cv::Point realBottomRight=cv::Point(realCenter.x+40, realCenter.y);
            ti=backTransmtx.at<double>(2,0)*realTopLeft.x+backTransmtx.at<double>(2,1)*realTopLeft.y+backTransmtx.at<double>(2,2);
            cv::Point topLeft=cv::Point((backTransmtx.at<double>(0,0)*realTopLeft.x+backTransmtx.at<double>(0,1)*realTopLeft.y+backTransmtx.at<double>(0,2))/ti,
                                        (backTransmtx.at<double>(1,0)*realTopLeft.x+backTransmtx.at<double>(1,1)*realTopLeft.y+backTransmtx.at<double>(1,2))/ti);
            ti=backTransmtx.at<double>(2,0)*realBottomRight.x+backTransmtx.at<double>(2,1)*realBottomRight.y+backTransmtx.at<double>(2,2);
            cv::Point bottomRight=cv::Point((backTransmtx.at<double>(0,0)*realBottomRight.x+backTransmtx.at<double>(0,1)*realBottomRight.y+backTransmtx.at<double>(0,2))/ti,
                                            (backTransmtx.at<double>(1,0)*realBottomRight.x+backTransmtx.at<double>(1,1)*realBottomRight.y+backTransmtx.at<double>(1,2))/ti);
            int l = sqrt(pow(topLeft.x-bottomRight.x, 2)+pow(topLeft.y-bottomRight.y,2));
            
            box.x-=l;
            box.y-=l;
            box.width=2*l;
            box.height=2*l;
            rectangle(dst, box, Scalar(0,255,0));
            if(box.x < 0){
                box.width += box.x;
                box.x=0;
            }
            if(box.y < 0){
                box.height += box.y;
                box.y = 0;
            }
            if(box.y + box.height > src.rows){
                box.height = src.rows - box.y - 1;
            }
            if(box.x + box.width > src.cols){
                box.width = src.cols - box.x - 1;
            }
            
            Mat rs(src,box);
            Mat ch[4];
            split(rs,ch);
            Canny( ch[2], ch[2], 20, 100, 3);
            ch[2].convertTo(ch[2], CV_8U);
            vector<Vec3f> circles;
            HoughCircles( ch[2], circles, 3, 1, 2*l/3, 5, 10, l/3, 3*l/4 );
            for( size_t i = 0; i < circles.size(); i++ )
            {
                cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
                center.x += box.x;
                center.y += box.y;
                int radius = cvRound(circles[i][2]);
                
                circle( dst, center, 3, Scalar(0,255,0), -1, 4, 0 );
                
                int count=0, total=0;
                //If image is clear
                if(m > 150){
                    NSLog(@"Clear image");
                    for(int j=center.y; j<center.y+radius; j++){
                        for(int k=center.x - radius; k<center.x+radius; k++) {
                            if(j<channels[2].rows&&k<channels[2].cols){
                                total++;
                                if(channels[2].at<unsigned char>(j,k) < m - 15 && channels[2].at<unsigned char>(j,k) > 0){
                                    count++;
                                    dst.at<Vec4b>(j,k)=Vec4b(0,255,0,255);
                                }
                            }
                        }
                    }
                    total /=2;
                }
                //image is dark
                else{
                    for(int j=center.y-radius; j<center.y; j++){
                        for(int k=center.x - radius; k<center.x+radius; k++) {
                            if(j < channels[2].rows && k < channels[2].cols){
                                total++;
                                if(channels[2].at<unsigned char>(j,k) > m + 35){
                                    count++;
                                    dst.at<Vec4b>(j,k)=Vec4b(0,255,0,255);
                                }
                            }
                        }
                    }
                    total /=4;
                }
                NSLog(@"count : %d", count);
                NSLog(@"total : %d", total);
                if(count>total){
                    balls.push_back(center);
                    cv::circle( dst, center, radius, Scalar(0,255,0), 1, 3, 0 );
                }
            }
        }
    }
    
    return dst;
    
}

- (Mat) detectPig:(Mat)src{
    Mat HSV, imgGray, blurred;
    vector<Mat> channels(3);
    
    cv::GaussianBlur( src, blurred, cv::Size(17,17), 0, 0, BORDER_DEFAULT );
    
    //Find the cochon
    cv::cvtColor(blurred,HSV,COLOR_RGB2HSV);
    
    imgGray = Mat::zeros(HSV.rows, HSV.cols, CV_8UC1);
    split(HSV, channels);
    for(int j=0; j<HSV.rows; j++){
        for(int k=0; k<HSV.cols; k++) {
            if((channels[0].at<unsigned char>(j,k) > 160 || channels[0].at<unsigned char>(j,k) < 30) &&
               channels[1].at<unsigned char>(j,k) > 90 &&
               channels[2].at<unsigned char>(j,k) > 70){
                imgGray.at<unsigned char>(j, k) = 255;
            }
        }
    }
    
    vector<vector<cv::Point> > pigs;
    findContours(imgGray, pigs, RETR_EXTERNAL, CHAIN_APPROX_NONE);
    cout<<pigs.size()<<endl;
    // Check different contour and verify approximative square box around contour
    if(pigs.size()>0){
        float area=0;
        int c=-1;
        for(int i=0;i<pigs.size();i++){
            cv::Rect box=boundingRect(pigs[i]);
            if(box.width<1.5*box.height||box.width>0.6*box.height){
                float a=box.width*box.height;
                if(a>area){
                    c=i;
                }
            }
        }
        cv::Rect box=boundingRect(pigs[c]);
        rectangle(src, box, Scalar(0,255,0), 2);
        if(c>=0){//Pig exist
            cv::Point center(box.x+box.width/2, box.y+box.height/2);
            int radius=(box.width+box.height)/4;
            cv::circle( src, center, 3, Scalar(0,255,0), -1, 4, 0 );
            cv::circle( src, center, radius, Scalar(0,0,255), 1, 3, 0 );
            double ti=transmtx.at<double>(2,0)*center.x+transmtx.at<double>(2,1)*center.y+transmtx.at<double>(2,2);
            pig=Point2f((transmtx.at<double>(0,0)*center.x+transmtx.at<double>(0,1)*center.y+transmtx.at<double>(0,2))/ti,
                        (transmtx.at<double>(1,0)*center.x+transmtx.at<double>(1,1)*center.y+transmtx.at<double>(1,2))/ti);
            
        }
    }
    return src;
    
}

- (Mat) searchDistances:(Mat)src{
    vector<cv::Point2f> realBalls;
    vector<uint> distances;
    for(int i=0; i<balls.size();i++){
        cv::Point center=balls[i];
        double ti=transmtx.at<double>(2,0)*center.x+transmtx.at<double>(2,1)*center.y+transmtx.at<double>(2,2);
        realBalls.push_back(Point2f((transmtx.at<double>(0,0)*center.x+transmtx.at<double>(0,1)*center.y+transmtx.at<double>(0,2))/ti,
                                    (transmtx.at<double>(1,0)*center.x+transmtx.at<double>(1,1)*center.y+transmtx.at<double>(1,2))/ti));
    }
    vector<cv::Point2f> tempRealBalls;
    vector<cv::Point2f> tempBalls;
    
    for(int i=0;i<balls.size();i++){
        bool to_add=true;
        for(int j=i+1;j<balls.size();j++){
            int d=sqrt(pow(realBalls[i].x-realBalls[j].x,2)+pow(realBalls[i].y-realBalls[j].y,2));
            if(d<40){
                to_add=false;
            }
        }
        if(to_add){
            tempRealBalls.push_back(realBalls[i]);
            tempBalls.push_back(balls[i]);
        }
    }
    balls.clear();
    balls=tempBalls;
    realBalls.clear();
    realBalls=tempRealBalls;
    
    for(int i=0;i<realBalls.size();i++){
        distances.push_back(sqrt(pow(realBalls[i].x-pig.x,2)+pow(realBalls[i].y-pig.y,2)));
    }
    bool order=true;
    if(balls.size()>0){
        while(order){
            order=false;
            for(int i=0;i<(balls.size()-1);i++){
                //NSLog(@"i %d", i);
                if(distances[i]>distances[i+1]){
                    order=true;
                    uint d=distances[i];
                    distances[i]=distances[i+1];
                    distances[i+1]=d;
                    Point2f bf=realBalls[i];
                    realBalls[i]=realBalls[i+1];
                    realBalls[i+1]=bf;
                    cv::Point b=balls[i];
                    balls[i]=balls[i+1];
                    balls[i+1]=b;
                }
            }
        }
    }
    for(int i=0; i<balls.size();i++){
        cv::putText(src, to_string(i+1), balls[i], FONT_HERSHEY_SIMPLEX, 1, Scalar(0,255,255), 3);
        //NSLog(@"ball %d at x %f y %f", i, balls[i].x, balls[i].y);
    }
    NSLog(@"%lu balls", balls.size());
    return src;
}

- (UIImage *) detection:(UIImage *)pickedImage{
    Mat src, imgCropped, imgWithBalls, finalImg, order;
    
    //Clearing old detection
    balls.clear();
    
    
    
    src = [self cvMatFromUIImage:pickedImage];
    //Detect the markers
    
    vector<Point2f> points = [self detectMarkers:src];
    //Crop the image with the points given by the user
    vector<Mat> rets = [self crop:src pointCoords:points];
    //Detect the balls using reflects
    imgWithBalls = [self detectBalls:rets];
    //detect the pig
    finalImg = [self detectPig:imgWithBalls];
    //With order written
    order=[self searchDistances:finalImg];

    
    return [self UIImageFromCVMat:order];
}


- (CGPoint) getFirstCoordinates{
    CGPoint point;
    point.x = balls[0].x;
    point.y = balls[0].y;
    return point;
}
@end
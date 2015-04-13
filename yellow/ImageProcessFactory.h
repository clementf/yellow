//
//  ImageProcessFactory.h
//  yellow
//
//  Created by Boris Moriniere on 02/03/2015.
//  Copyright (c) 2015 isen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface ImageProcessFactory : NSObject

//@property (strong, nonatomic) UIImage *pickedImg;

- (UIImage *) blurImage:(UIImage *)pickedImage;
- (UIImage *) transformPerspective:(UIImage *)pickedImage pointCoords:(NSArray *) points;

@end
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


- (UIImage *) detection:(UIImage *)pickedImage;
- (NSArray *) getAllCoordinates;
- (NSString *) getError;

@end
//
//  UIView+ConstraintHelpers.h
//  PractitionerPortal
//
//  Created by Kashif Shaikh on 12/22/2013.
//  Copyright (c) 2013 PointClickCare. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Debug)
+ (void) colorViewsRandomly:(UIView*)view;
+ (void) logViewRect:(UIView*)view level:(NSInteger)level;
+ (UIImageView *)writeImageViewForView:(UIView *)view;
+ (UIImageView *)writeImageView:(UIImageView *)imageView;
@end

//
//  UIView+ConstraintHelpers.h

#import <UIKit/UIKit.h>

@interface UIView (Debug)
+ (void) colorViewsRandomly:(UIView*)view;
+ (void) logViewRect:(UIView*)view level:(NSInteger)level;
+ (UIImageView *)writeImageViewForView:(UIView *)view;
+ (UIImageView *)writeImageView:(UIImageView *)imageView;
@end

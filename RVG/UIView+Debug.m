//
//  UIView+ConstraintHelpers.m

#import <UIKit/UIKit.h>
#import "UIView+Debug.h"

@implementation UIView (Debug)
+ (void) colorViewsRandomly:(UIView*)view {
    view.backgroundColor = [UIView randomColor];
    for (UIView *subview in view.subviews) {
        [UIView colorViewsRandomly:subview];
    }
}

+ (void) logViewRect:(UIView*)view level:(NSInteger)level {
    NSString *indentation = [@"" stringByPaddingToLength:level * 2 withString:@"  " startingAtIndex:0];
    NSLog(@"%@%@: x:%.0f y:%.0f w:%.0f h:%.0f", indentation, NSStringFromClass(view.class), CGRectGetMinX(view.frame), CGRectGetMinY(view.frame), CGRectGetWidth(view.frame), CGRectGetHeight(view.frame));
    for (UIView *subview in view.subviews) {
        [UIView logViewRect:subview level:level + 1];
    }
}


+ (UIColor*)randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    CGFloat alpha = (3 + arc4random() % 5) / 10.0; // 0.3 to 0.7
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    return color;
}


+ (UIImageView *)writeImageViewForView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, 0.0);
    [view drawViewHierarchyInRect:view.frame afterScreenUpdates:NO];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    UIImageView* imageView = [[UIImageView alloc] initWithImage:snapshot];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [UIView guid]]];
    
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"file: %@", filePath);
#endif
    // Save image.
    [UIImagePNGRepresentation(imageView.image) writeToFile:filePath atomically:YES];

    return imageView;
}

+ (UIImageView *)writeImageView:(UIImageView *)imageView
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [UIView guid]]];
    
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"file: %@", filePath);
#endif
    // Save image.
    [UIImagePNGRepresentation(imageView.image) writeToFile:filePath atomically:YES];
    
    return imageView;
}

+ (NSString*)guid
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)(string);
}

@end

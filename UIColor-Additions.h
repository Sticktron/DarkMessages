#import <UIKit/UIColor.h>


@interface UIColor (DarkMessages)

+ (UIColor *)colorFromHexString:(NSString *)hexString;

- (UIImage *)thumbnailWithSize:(CGSize)size;
- (BOOL)isLightColor;

@end

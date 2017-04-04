//
//  DarkMessagesTheme.h
//  Theme controller for DarkMessages
//
//  ©2017 Sticktron
//

@interface DarkMessagesTheme : NSObject

+ (UIColor *)tintColor;
+ (UIColor *)bgColor;
+ (UIColor *)separatorColor;
+ (UIColor *)cellBgColor;
+ (UIColor *)cellTextColor;
+ (UIColor *)footerTextColor;
+ (UIColor *)switchFillColor;
+ (UIColor *)switchKnobColor;
+ (UIColor *)switchBorderColor;
+ (UIColor *)chevronColor;

+ (void)themeStuffInClasses:(NSArray *)classes;

+ (NSString *)defaultBalloonColorInHexForKey:(NSString *)key;

@end

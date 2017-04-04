//
//  DarkMessagesTheme.m
//  Theme controller for DarkMessages
//
//  ©2017 Sticktron
//

#import "DarkMessagesTheme.h"


#define BLUE 		[UIColor colorWithRed:15/255.0 green:132/255.0 blue:252/255.0 alpha:1] //#0F84FC
#define WHITE		[UIColor colorWithWhite:1 alpha:1]
#define BLACK 		[UIColor colorWithWhite:0 alpha:1]
#define GRAY_9	 	[UIColor colorWithWhite:0.09 alpha:1.0] // #171717
#define GRAY_11 	[UIColor colorWithRed:0.11 green:0.11 blue:0.114 alpha:1.0] // #1c1c1d
#define GRAY_20		[UIColor colorWithRed:0.196 green:0.196 blue:0.200 alpha:1.0] // #323233
#define GRAY_40		[UIColor colorWithRed:0.39 green:0.39 blue:0.40 alpha:1.0] // 50% of systemGrayColor
#define GRAY_50		[UIColor colorWithRed:0.49 green:0.49 blue:0.50 alpha:1.0] // #7d7d80
#define GRAY_56		[UIColor colorWithRed:0.56 green:0.56 blue:0.58 alpha:1.0] // systemGrayColor (#8f8f94?)
#define GRAY_78		[UIColor colorWithRed:0.78 green:0.78 blue:0.80 alpha:1.0] // systemMidGrayColor


@implementation DarkMessagesTheme

+ (UIColor *)tintColor { return GRAY_9; }
+ (UIColor *)bgColor { return GRAY_9; }
+ (UIColor *)separatorColor { return GRAY_20; }
+ (UIColor *)cellBgColor { return GRAY_11; }
+ (UIColor *)cellTextColor { return WHITE; }
+ (UIColor *)footerTextColor { return GRAY_56; }
+ (UIColor *)switchFillColor { return BLUE; }
+ (UIColor *)switchKnobColor { return BLACK; }
+ (UIColor *)switchBorderColor { return BLUE; }
+ (UIColor *)chevronColor { return BLUE; }

+ (void)themeStuffInClasses:(NSArray *)classes {
	
	// Table BG
	[[UITableView appearanceWhenContainedInInstancesOfClasses:classes] setBackgroundColor:[DarkMessagesTheme bgColor]];
	
	// Separators
	[[UITableView appearanceWhenContainedInInstancesOfClasses:classes] setSeparatorColor:[DarkMessagesTheme separatorColor]];
	
	// Cell BG
	[[NSClassFromString(@"PSTableCell") appearanceWhenContainedInInstancesOfClasses:classes] setBackgroundColor:[DarkMessagesTheme cellBgColor]];
	
	// Cell Disclosure Image
	[[NSClassFromString(@"PSTableCell") appearanceWhenContainedInInstancesOfClasses:classes] setTintColor:[DarkMessagesTheme chevronColor]];
	
	// Cell Label
	// ?? (tinted in PSTableCell subclass for now)
	
	// Section Text
	[[UILabel appearanceWhenContainedInInstancesOfClasses:classes] setTextColor:[DarkMessagesTheme footerTextColor]];
	
	// Switch
	[[UISwitch appearanceWhenContainedInInstancesOfClasses:classes] setOnTintColor:[DarkMessagesTheme switchFillColor]];
	[[UISwitch appearanceWhenContainedInInstancesOfClasses:classes] setThumbTintColor:[DarkMessagesTheme switchKnobColor]];
	[[UISwitch appearanceWhenContainedInInstancesOfClasses:classes] setTintColor:[DarkMessagesTheme switchBorderColor]];
}

+ (NSString *)defaultBalloonColorInHexForKey:(NSString *)key {
	if ([key isEqualToString:@"BlueBalloonColor"]) {
		return @"#0f84fc";
	} else if ([key isEqualToString:@"GreenBalloonColor"]) {
		return @"#00d248";
	} else if ([key isEqualToString:@"GrayBalloonColor"]) {
		return @"#333333";
	} else {
		return @"#000000"; // error
	}
}

@end

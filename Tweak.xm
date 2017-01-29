//
//  DarkMessages
//  Dark theme for Messages app
//  For iOS 10
//
//  @sticktron
//
//  Contributers: HiDaN4
//

#import "Headers.h"

#ifdef DEBUG
#define DebugLog(s, ...) \
	NSLog(@"[DarkMessages] >> %@", [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
#define DebugLog(s, ...)
#endif


static CKUIThemeDark *darkTheme;

//------------------------------------------------------------------------------

%group Phone
%hook CKUIBehaviorPhone
- (id)theme {
	return darkTheme;
}
%end
%end

//------------------------------------------------------------------------------

%group Pad
%hook CKUIBehaviorPad
- (id)theme {
	return darkTheme;
}
%end
%end

//------------------------------------------------------------------------------

%group Common

// fix navbar style
%hook CKAvatarNavigationBar
- (void)_setBarStyle:(int)style {
	%orig(1);
}
- (int)barStyle {
	return 1;
}
%end

// fix contact name label in navbar
%hook CKAvatarContactNameCollectionReusableView
- (void)setStyle:(int)style {
	%orig(3);
}
- (int)style {
	return 3;
}
%end

// fix 'Compose New' label
%hook CKComposeNavbarManagerContentView
- (void)layoutSubviews {
	%orig;
	
	CKNavigationBarCanvasView *cv = [self canvasView];
	UILabel *tv = (UILabel *)[cv titleView];
	tv.textColor = UIColor.whiteColor;
}
%end

// fix group chat title label
%hook CKDetailsGroupNameCell
- (UILabel*)textLabel {
	UILabel* tl = %orig;
	tl.textColor = UIColor.whiteColor;
	return tl;
}
%end

// fix group chat contact name labels
%hook CKDetailsContactsTableViewCell
- (UILabel*)nameLabel {
	UILabel* nl = %orig;
	nl.textColor = UIColor.whiteColor;
	return nl;
}
%end

// %hook CKComposeNavbarManagerContentView
// - (void)layoutSubviews {
// 	%orig;
//
// 	CKNavigationBarCanvasView *cv = [self canvasView];
// 	if (cv) {
// 		UILabel *tv = (UILabel *)[cv titleView];
// 		if (tv) {
// 			tv.textColor = UIColor.whiteColor;
// 		}
// 	}
// }
// %end

%end

//------------------------------------------------------------------------------

%ctor {
	@autoreleasepool {
		DebugLog(@"Init'ing tweak");
		
		darkTheme = [[%c(CKUIThemeDark) alloc] init];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			DebugLog(@"Device = iPad");
			%init(Pad);
		} else {
			DebugLog(@"Device = iPhone");
			%init(Phone);
		}
		
		%init(Common);
	}
}

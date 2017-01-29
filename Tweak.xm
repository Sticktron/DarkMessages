//
//  DarkMessages
//  Dark theme for Messages app.
//  iOS 10
//
//  @sticktron
//

#ifdef DEBUG
#define DebugLog(s, ...) \
	NSLog(@"[DarkMessages] >> %@", [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
#define DebugLog(s, ...)
#endif

#import "Headers.h"

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

// fix navbar: style
%hook CKAvatarNavigationBar
- (void)_setBarStyle:(int)style {
	%orig(1);
}
%end

// fix navbar: contact names
%hook CKAvatarContactNameCollectionReusableView
- (void)setStyle:(int)style {
	%orig(3);
}
%end

// fix navbar: group names
%hook CKAvatarTitleCollectionReusableView
- (void)setStyle:(int)style {
	%orig(3);
}
%end

// fix navbar new message label
%hook CKNavigationBarCanvasView
- (void)setTitleView:(id)titleView {
	if (titleView && [titleView respondsToSelector:@selector(setTextColor:)]) {
		[(UILabel *)titleView setTextColor:UIColor.whiteColor];
	}
	%orig(titleView);
}
%end

// fix group details: contact names
%hook CKDetailsContactsTableViewCell
- (UILabel *)nameLabel {
	UILabel *nl = %orig;
	nl.textColor = UIColor.whiteColor;
	return nl;
}
%end

%end

//------------------------------------------------------------------------------

%ctor {
	@autoreleasepool {
		darkTheme = [[%c(CKUIThemeDark) alloc] init];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			%init(Pad);
		} else {
			%init(Phone);
		}
		
		%init(Common);
	}
}

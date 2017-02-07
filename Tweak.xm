//
//  Tweak.xm
//
//  DarkMessages
//  Dark theme for the iOS 10 Messages app.
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessages]"
#import "DebugLog.h"

#import "Headers.h"


CFStringRef kPrefsAppID = CFSTR("com.sticktron.darkmessages");
CFStringRef kPrefsEnabledKey = CFSTR("Enabled");

static BOOL isEnabled;
static CKUIThemeDark *darkTheme;


static void killMessages() {
	NSLog(@"DarkMessages >> Terminating MobileSMS...");
	[[UIApplication sharedApplication] terminateWithSuccess];
}

static void loadSettings() {
	CFPreferencesAppSynchronize(kPrefsAppID);
	Boolean valid;
	Boolean value = CFPreferencesGetAppBooleanValue(kPrefsEnabledKey, kPrefsAppID, &valid);
	isEnabled = valid ? (BOOL)value : YES; // enabled by default
	DebugLog(@"Loaded settings >> is enabled? %@", isEnabled?@"yes":@"no");
}

static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLog(@"Notice: Preferences have changed!");
	BOOL oldSetting = isEnabled;
	loadSettings();
	if (isEnabled != oldSetting) {
		killMessages();
	}
}


// MobileSMS Hooks -------------------------------------------------------------

%group Phone
%hook CKUIBehaviorPhone
- (id)theme {
	// return isEnabled ? darkTheme : %orig;
	return darkTheme;
}
%end
%end

//------------------------------------------------------------------------------

%group Pad
%hook CKUIBehaviorPad
- (id)theme {
	// return isEnabled ? darkTheme : %orig;
	return darkTheme;
}
%end
%end

//------------------------------------------------------------------------------

%group Common

// fix navbar: style
%hook CKAvatarNavigationBar
- (void)_setBarStyle:(int)style {
	// isEnabled ? %orig(1) : %orig;
	%orig(1);
}
%end

// fix navbar: contact names
%hook CKAvatarContactNameCollectionReusableView
- (void)setStyle:(int)style {
	// isEnabled ? %orig(3) : %orig;
	%orig(3);
}
%end

// fix navbar: group names
%hook CKAvatarTitleCollectionReusableView
- (void)setStyle:(int)style {
	// isEnabled ? %orig(3) : %orig;
	%orig(3);
}
%end

// fix navbar: new message label
%hook CKNavigationBarCanvasView
- (id)titleView {
	// if (isEnabled) {
		id tv = %orig;
		if (tv && [tv respondsToSelector:@selector(setTextColor:)]) {
			[(UILabel *)tv setTextColor:UIColor.whiteColor];
		}
		return tv;
	// } else {
	// 	return %orig;
	// }
}
%end

// fix group details: contact names
%hook CKDetailsContactsTableViewCell
- (UILabel *)nameLabel {
	// if (isEnabled) {
		UILabel *nl = %orig;
		nl.textColor = UIColor.whiteColor;
		return nl;
	// } else {
	// 	return %orig;
	// }
}
%end

// fix message entry inactive color
%hook CKMessageEntryView
- (UILabel *)collpasedPlaceholderLabel {
	UILabel *label = %orig;
	label.textColor = [UIColor colorWithRed:0.522 green:0.557 blue:0.6 alpha:1];
	return label;
}
%end


// tests ///////

// %hook CKUIThemeDark
// - (id)blue_balloonColors {
// 	return @[ [UIColor colorWithRed:1 green:0 blue:0.5 alpha:1], [UIColor colorWithRed:0.5 green:0 blue:1 alpha:1] ];
// }
// - (id)gray_balloonColors {
// 	return @[ [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1], [UIColor colorWithRed:0 green:1 blue:0.5 alpha:1] ];
// }
// %end

// %hook CKAudioProgressView
// - (void)setStyle:(int)arg1 {
// 	%log;
// 	%orig;
// }
// %end
// %hook CKAvatarPickerViewController
// - (void)setStyle:(int)arg1 {
// 	%log;
// 	%orig;
// }
// %end
// %hook CKFullScreenAppNavbarManager
// - (void)setStyle:(int)arg1 {
// 	%log;
// 	%orig;
// }
// %end
// %hook CKMessageEntryView
// - (void)setStyle:(int)arg1 {
// 	// default is 4; 2 is darker, 1 is lighter
// 	%log;
// 	%orig;
// }
// %end

%end

//------------------------------------------------------------------------------

%ctor {
	@autoreleasepool {
		DebugLog(@"Loading Tweak...");
		
		loadSettings();
		if (isEnabled) {
			darkTheme = [[%c(CKUIThemeDark) alloc] init];
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				%init(Pad);
			} else {
				%init(Phone);
			}
			%init(Common);
		}
		
		// listen for settings changes
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)handleSettingsChanged,
			CFSTR("com.sticktron.darkmessages.settingschanged"),
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
	}
}

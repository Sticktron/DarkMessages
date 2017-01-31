//
//  DarkMessages
//  Dark theme for Messages app.
//  iOS 10
//
//  @sticktron
//

#import "Headers.h"

static CKUIThemeDark *darkTheme;
static BOOL isEnabled = YES;

static void loadSettings() {
	CFStringRef prefsAppID = CFSTR("com.sticktron.darkmessages");
	NSDictionary *settings = nil;
	
	CFPreferencesAppSynchronize(prefsAppID);
	CFArrayRef keyList = CFPreferencesCopyKeyList(prefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (keyList) {
		settings = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, prefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		if (settings && settings[@"Enabled"] && [settings[@"Enabled"] boolValue] == NO) {
			isEnabled = NO;
		}
		CFRelease(keyList);
	}
	CFRelease(prefsAppID);
}

static void reloadSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	// restart the Messages app
	HBLogInfo(@"Terminating MobileSMS");
	[[UIApplication sharedApplication] terminateWithSuccess];
}

// Hooks -----------------------------------------------------------------------

%group Phone

%hook CKUIBehaviorPhone
- (id)theme {
	return isEnabled ? darkTheme : %orig;
}
%end

%end

//------------------------------------------------------------------------------

%group Pad

%hook CKUIBehaviorPad
- (id)theme {
	return isEnabled ? darkTheme : %orig;
}
%end

%end

//------------------------------------------------------------------------------

%group Common

// fix navbar: style
%hook CKAvatarNavigationBar
- (void)_setBarStyle:(int)style {
	isEnabled ? %orig(1) : %orig;
}
%end

// fix navbar: contact names
%hook CKAvatarContactNameCollectionReusableView
- (void)setStyle:(int)style {
	isEnabled ? %orig(3) : %orig;
}
%end

// fix navbar: group names
%hook CKAvatarTitleCollectionReusableView
- (void)setStyle:(int)style {
	isEnabled ? %orig(3) : %orig;
}
%end

// fix navbar: new message label
%hook CKNavigationBarCanvasView
- (void)setTitleView:(id)titleView {
	if (isEnabled) {
		if (titleView && [titleView respondsToSelector:@selector(setTextColor:)]) {
			[(UILabel *)titleView setTextColor:UIColor.whiteColor];
		}
		%orig(titleView);
	} else {
		%orig;
	}
}
%end

// fix group details: contact names
%hook CKDetailsContactsTableViewCell
- (UILabel *)nameLabel {
	if (isEnabled) {
		UILabel *nl = %orig;
		nl.textColor = UIColor.whiteColor;
		return nl;
	} else {
		return %orig;
	}
}
%end

%end

//------------------------------------------------------------------------------

%ctor {
	@autoreleasepool {
		loadSettings();
		
		darkTheme = [[%c(CKUIThemeDark) alloc] init];
		
		// init hooks
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			%init(Pad);
		} else {
			%init(Phone);
		}
		%init(Common);
		
		// listen for notifications from settings
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)reloadSettings,
			CFSTR("com.sticktron.darkmessages.settingschanged"),
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately);
	}
}

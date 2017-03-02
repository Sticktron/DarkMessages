//
//  Tweak.xm
//  DarkMessages
//
//  Forces use of the dark theme found in ChatKit in iOS 10.
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessages]"
#import "DebugLog.h"

#import "DarkMessages.h"


static BOOL isEnabled;
static CKUIThemeDark *darkTheme;


static void loadSettings() {
	CFPreferencesAppSynchronize(kPrefsAppID);
	Boolean valid;
	Boolean value = CFPreferencesGetAppBooleanValue(kPrefsEnabledKey, kPrefsAppID, &valid);
	isEnabled = valid ? (BOOL)value : YES; // enabled by default
	DebugLogC(@"Loaded settings >> isEnabled? %@", isEnabled?@"yes":@"no");
}

static void askToDie() {
	DebugLogC(@"askToDie()");
	
	UIAlertController *alert = [UIAlertController
		alertControllerWithTitle:@"Dark Mode Toggled"
		message:@"Restart Messages to change mode."
		preferredStyle:UIAlertControllerStyleAlert
	];
	
	[alert addAction:[UIAlertAction
		actionWithTitle:@"Now"
		style:UIAlertActionStyleDestructive
	    handler:^(UIAlertAction *action) {
			DebugLogC(@"asking SpringBoard to restarted MobileSMS...");
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
				kRelaunchMobileSMSNotification, NULL, NULL, true
			);
        }]
	];
	[alert addAction:[UIAlertAction
		actionWithTitle:@"Later"
		style:UIAlertActionStyleCancel
		handler:^(UIAlertAction *action) {
			// do nothing
		}]
	];
	
	[[[UIWindow keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
}

static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"*** Notice: %@", name);
	
	BOOL oldSetting = isEnabled;
	loadSettings();
	
	// if in MobileSMS: toggle dark mode if necessary
 	if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.MobileSMS"]) {
		if (isEnabled != oldSetting) {
			DebugLogC(@"Dark mode has changed, we need to restart MobileSMS");
			
			if ([[UIApplication sharedApplication] isSuspended]) {
				DebugLogC(@"MobileSMS is suspended, killing quietly");
				[[UIApplication sharedApplication] terminateWithSuccess];
			} else {
				DebugLogC(@"MobileSMS is front, asking user to restart");
				askToDie();
			}
		}
	}
}


%hook CKUIBehaviorPhone
- (id)theme {
	return isEnabled ? darkTheme : %orig;
}
%end

%hook CKUIBehaviorPad
- (id)theme {
	return isEnabled ? darkTheme : %orig;
}
%end

// fix navbar: style
%hook CKAvatarNavigationBar
- (void)_setBarStyle:(int)style {
	if (isEnabled) {
		%orig(1);
	} else {
		%orig;
	}
}
%end

// fix navbar: contact names
%hook CKAvatarContactNameCollectionReusableView
- (void)setStyle:(int)style {
	if (isEnabled) {
		%orig(3);
	} else {
		%orig;
	}
}
%end

// fix navbar: group names
%hook CKAvatarTitleCollectionReusableView
- (void)setStyle:(int)style {
	if (isEnabled) {
		%orig(3);
	} else {
		%orig;
	}
}
%end

// fix navbar: new message label
%hook CKNavigationBarCanvasView
- (id)titleView {
	if (isEnabled) {
		id tv = %orig;
		if (tv && [tv respondsToSelector:@selector(setTextColor:)]) {
			[(UILabel *)tv setTextColor:UIColor.whiteColor];
		}
		return tv;
	} else {
		return %orig;
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

// fix message entry inactive color
%hook CKMessageEntryView
- (UILabel *)collpasedPlaceholderLabel {
	if (isEnabled) {
		UILabel *label = %orig;
		label.textColor = [darkTheme entryFieldDarkStyleButtonColor];
		return label;
	} else {
		return %orig;
	}
}
%end

// %hook CKUIThemeDark
// - (id)blue_balloonColors {
// 	return @[ [UIColor colorWithRed:1 green:0 blue:0.5 alpha:1], [UIColor colorWithRed:0.5 green:0 blue:1 alpha:1] ];
// }
// - (id)gray_balloonColors {
// 	return @[ [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1], [UIColor colorWithRed:0 green:1 blue:0.5 alpha:1] ];
// }
// %end


%ctor {
	@autoreleasepool {
		DebugLogC(@"Loading Tweak...");
		
		loadSettings();
		
		darkTheme = [[%c(CKUIThemeDark) alloc] init];
		%init;
		
		// listen for changes to settings
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)handleSettingsChanged,
			kSettingsChangedNotification,
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
	}
}

//
//  DarkMessages.xm
//  DarkMessages
//
//  Dark theme for the iOS 10 Messages app.
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
	DebugLog(@"Loaded settings >> isEnabled? %@", isEnabled?@"yes":@"no");
}

static void askToDie() {
	DebugLog(@"askToDie()");
	
	UIAlertController *alert = [UIAlertController
		alertControllerWithTitle:@"Dark Mode Toggled"
		message:@"Messages needs to restart."
		preferredStyle:UIAlertControllerStyleAlert
	];
	
	[alert addAction:[UIAlertAction
		actionWithTitle:@"Now"
		style:UIAlertActionStyleDefault
	    handler:^(UIAlertAction *action) {
			DebugLog(@"asking SpringBoard to restarted MobileSMS...");
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
	DebugLog(@"*** Notice: %@", name);
	DebugLog(@"handleSettingsChanged() responding");
	
	BOOL oldSetting = isEnabled;
	loadSettings();
	
	// toggle dark mode (only if necessary)
	if (isEnabled != oldSetting) {
		DebugLog(@"Dark mode has changed, we need to restart");
		
		if ([[UIApplication sharedApplication] isSuspended]) {
			DebugLog(@"MobileSMS is suspended, killing quietly");
			[[UIApplication sharedApplication] terminateWithSuccess];
		} else {
			DebugLog(@"MobileSMS is front, asking user to restart");
			askToDie();
		}
	}
}


%hook CKUIBehaviorPhone
- (id)theme {
	return darkTheme;
}
%end

%hook CKUIBehaviorPad
- (id)theme {
	return darkTheme;
}
%end

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

// fix navbar: new message label
%hook CKNavigationBarCanvasView
- (id)titleView {
	id tv = %orig;
	if (tv && [tv respondsToSelector:@selector(setTextColor:)]) {
		[(UILabel *)tv setTextColor:UIColor.whiteColor];
	}
	return tv;
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

// fix message entry inactive color
%hook CKMessageEntryView
- (UILabel *)collpasedPlaceholderLabel {
	UILabel *label = %orig;
	// label.textColor = [UIColor colorWithRed:0.522 green:0.557 blue:0.6 alpha:1];
	// label.textColor = [darkTheme entryFieldButtonColor];
	label.textColor = [darkTheme entryFieldDarkStyleButtonColor];
	return label;
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
		DebugLog(@"Loading Tweak...");
		
		loadSettings();
		
		if (isEnabled) {
			darkTheme = [[%c(CKUIThemeDark) alloc] init];
			%init;
		}
		
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

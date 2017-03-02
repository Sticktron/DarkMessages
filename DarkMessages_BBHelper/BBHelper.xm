//
//  DarkMessages_BBHelper.xm
//  DarkMessages
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessages_BBHelper]"
#import "../DebugLog.h"

#import "../DarkMessages.h"
#import <spawn.h>


static BOOL isEnabled;
static BOOL nightShiftControl;
static BOOL noctisControl;


static void setDarkMode(BOOL enabled) {
	DebugLogC(@"setDarkMode(%@) called", enabled?@"yes":@"no");
	
	// only set if different than current mode
	if (isEnabled != enabled) {
		isEnabled = enabled;
		DebugLogC(@"Dark Mode changed to: %d", isEnabled);
		
		// update prefs
		CFPreferencesSetAppValue(kPrefsEnabledKey, enabled ? kCFBooleanTrue : kCFBooleanFalse, kPrefsAppID);
		CFPreferencesAppSynchronize(kPrefsAppID);
		
		// tell MobileSMS it needs to restart
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
			kSettingsChangedNotification, NULL, NULL, true
		);
	} else {
		DebugLogC(@"already in mode (%@)", enabled?@"ON":@"OFF");
	}
}

static void loadSettings() {
	DebugLogC(@"loadSettings()");
	
	NSDictionary *settings = nil;
	CFPreferencesAppSynchronize(kPrefsAppID);
	CFArrayRef keyList = CFPreferencesCopyKeyList(kPrefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (keyList) {
		settings = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, kPrefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		DebugLogC(@"found user prefs: %@", settings);
		CFRelease(keyList);
	} else {
		DebugLogC(@"no user prefs, using defaults");
	}
	
	isEnabled = settings[@"Enabled"] ? [settings[@"Enabled"] boolValue] : YES;
	nightShiftControl = settings[@"NightShiftControl"] ? [settings[@"NightShiftControl"] boolValue] : NO;
	noctisControl = settings[@"NoctisControl"] ? [settings[@"NoctisControl"] boolValue] : NO;
	DebugLogC(@"settings >> DarkMode:%@; NightShiftControl:%@; NoctisControl:%@", isEnabled?@"yes":@"no", nightShiftControl?@"yes":@"no", noctisControl?@"yes":@"no");
}

static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"*** Notice: %@", name);
	loadSettings();
}

%hook NightModeControl
- (void)enableBlueLightReduction:(BOOL)enable withOption:(int)option {
	%orig;
	if (nightShiftControl) {
		if (enable) {
			DebugLog(@"night shift on");
			setDarkMode(YES);
		} else {
			DebugLog(@"night shift off");
			setDarkMode(NO);
		}
	}
}
%end

%ctor {
	@autoreleasepool {
		DebugLogC(@"Loading backboardd helper...");
		
		loadSettings();
		
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

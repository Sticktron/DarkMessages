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


static void loadSettings() {
	DebugLogC(@"loading settings...");
	
	NSDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
	isEnabled = settings[@"Enabled"] ? [settings[@"Enabled"] boolValue] : YES;
	nightShiftControl = settings[@"NightShiftControl"] ? [settings[@"NightShiftControl"] boolValue] : NO;
	DebugLogC(@"settings >> DarkMode:%@; NightShiftControl:%@", isEnabled?@"yes":@"no", nightShiftControl?@"yes":@"no");
}

static void setDarkMode(BOOL enabled) {
	DebugLogC(@"setDarkMode(%@) called", enabled?@"yes":@"no");
	
	// only set if different than current mode
	if (isEnabled != enabled) {
		isEnabled = enabled;
		DebugLogC(@"Dark Mode changed to: %d", isEnabled);
		
		// update prefs
		NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
		settings[@"Enabled"] = isEnabled ? @YES : @NO;
		[settings writeToFile:kPrefsPlistPath atomically:YES];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
			kSettingsChangedNotification, NULL, NULL, true
		);
	} else {
		DebugLogC(@"already in mode (%@)", enabled?@"ON":@"OFF");
	}
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

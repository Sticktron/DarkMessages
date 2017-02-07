//
//  DarkMessages_Helper.xm
//
//  DarkMessages
//  Dark theme for the iOS 10 Messages app.
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessages_Helper]"
#import "../DebugLog.h"

#import <Foundation/NSDistributedNotificationCenter.h>


static CFStringRef kPrefsAppID = CFSTR("com.sticktron.darkmessages");
static CFStringRef kPrefsEnabledKey = CFSTR("Enabled");
static CFStringRef kPrefsNoctisControlKey = CFSTR("NoctisControl");
// static CFStringRef kPrefsNightShiftControlKey = CFSTR("NightShiftControl");

static CFStringRef kNoctisAppID = CFSTR("com.laughingquoll.noctis");
static CFStringRef kNoctisEnabledKey = CFSTR("LQDDarkModeEnabled");

static BOOL hasNoctis;
static BOOL noctisControl = YES;
// static BOOL nightShiftControl = NO;


static void loadSettings() {
	CFPreferencesAppSynchronize(kPrefsAppID);
	Boolean value, valid;
	
	// NoctisControl?
	value = CFPreferencesGetAppBooleanValue(kPrefsNoctisControlKey, kPrefsAppID, &valid);
	if (valid) {
		noctisControl = (BOOL)value;
	}
	DebugLog(@"Loaded settings >> Noctis control enabled? %@", noctisControl?@"yes":@"no");
	
	// NightShiftControl?
	// value = CFPreferencesGetAppBooleanValue(kPrefsNightShiftControlKey, kPrefsAppID, &valid);
	// if (valid) {
	// 	nightShiftControl = (BOOL)value;
	// }
	// DebugLog(@"Loaded settings >> NightShift control enabled? %@", nightShiftControl?@"yes":@"no");
}

static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLog(@"Notice: Preferences have changed!");
	loadSettings();
}

static void setDarkMode(BOOL enabled) {
	DebugLog(@"Noctis was toggled: %@", enabled?@"ON":@"OFF");
	
	// update Preferences
	CFPreferencesSetAppValue(kPrefsEnabledKey, enabled ? kCFBooleanTrue : kCFBooleanFalse, kPrefsAppID);
	CFPreferencesAppSynchronize(kPrefsAppID);
	
	// tell MobileSMS
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
		CFSTR("com.sticktron.darkmessages.settingschanged"), NULL, NULL, true);
}

static void setupForNoctis() {
	// sync initial state with Noctis
	if (noctisControl) {
		CFPreferencesAppSynchronize(kNoctisAppID);
		Boolean valid;
		Boolean value = CFPreferencesGetAppBooleanValue(kNoctisEnabledKey, kNoctisAppID, &valid);
		DebugLog(@"Checking Noctis prefs, key is valid? %@", valid?@"yes":@"no");
		DebugLog(@"Checking Noctis prefs, value is? %@", value?@"yes":@"no");
		BOOL noctisEnabled = valid ? (BOOL)value : YES;
		DebugLog(@"Noctis enabled? %@", noctisEnabled?@"yes":@"no");
		setDarkMode(noctisEnabled);
	}
	
	[[NSNotificationCenter defaultCenter]
		addObserverForName:@"com.laughingquoll.noctis.enablenotification"
		object:nil
		queue:[NSOperationQueue mainQueue]
		usingBlock:^(NSNotification *note) {
			DebugLog(@"Notice: Noctis toggled on!");
			if (noctisControl) {
				setDarkMode(YES);
			}
		}
	];
		
	[[NSNotificationCenter defaultCenter]
		addObserverForName:@"com.laughingquoll.noctis.disablenotification"
		object:nil
		queue:[NSOperationQueue mainQueue]
		usingBlock:^(NSNotification *note) {
			DebugLog(@"Notice: Noctis toggled off!");
			if (noctisControl) {
				setDarkMode(NO);
			}
		}
	];
}


%ctor {
	@autoreleasepool {
		DebugLog(@"Loading Helper...");
		
		loadSettings();
		
		hasNoctis = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Noctis.dylib"];
		if (hasNoctis) {
			setupForNoctis();
		}
		
		// listen for settings changes
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)handleSettingsChanged,
			CFSTR("com.sticktron.darkmessages.settingschanged"),
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
		
		// Debug: catch all notifications
		// [[NSNotificationCenter defaultCenter]
		// 	addObserverForName:nil
		// 	object:nil
		// 	queue:nil
		// 	usingBlock:^(NSNotification *note) {
		// 		DebugLog(@"***** %@", note.name);
		// 	}
		// ];
		// [[NSDistributedNotificationCenter defaultCenter]
		// 	addObserverForName:nil
		// 	object:nil
		// 	queue:nil
		// 	usingBlock:^(NSNotification *note) {
		// 		DebugLog(@"***** %@", note.name);
		// 	}
		// ];
	}
}

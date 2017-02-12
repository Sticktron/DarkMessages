//
//  DarkMessages_Helper.xm
//  DarkMessages
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessages_Helper]"
#import "../DebugLog.h"

#import "../DarkMessages.h"
#import <spawn.h>


static BOOL isEnabled;
static BOOL nightShiftControl;
static BOOL noctisControl;


static void setDarkMode(BOOL enabled) {
	DebugLog(@"setDarkMode(%@) called", enabled?@"yes":@"no");
	
	// only set if different than current mode
	if (isEnabled != enabled) {
		isEnabled = enabled;
		DebugLog(@"Dark Mode changed to: %d", isEnabled);
		
		// update prefs
		CFPreferencesSetAppValue(kPrefsEnabledKey, enabled ? kCFBooleanTrue : kCFBooleanFalse, kPrefsAppID);
		CFPreferencesAppSynchronize(kPrefsAppID);
		
		// tell MobileSMS it needs to restart
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
			kSettingsChangedNotification, NULL, NULL, true
		);
	} else {
		DebugLog(@"already in mode (%@)", enabled?@"ON":@"OFF");
	}
}

static BOOL noctisEnabled() {
	DebugLog(@"Checking Noctis prefs...");
	
	CFPreferencesAppSynchronize(kNoctisAppID);
	Boolean valid;
	Boolean value = CFPreferencesGetAppBooleanValue(kNoctisEnabledKey, kNoctisAppID, &valid);
	BOOL enabled = valid ? value : YES;
	DebugLog(@"...Noctis is: %@", enabled?@"on":@"off");
	
	return enabled;
}

static BOOL nightShiftEnabled() {
	DebugLog(@"Checking for NightShift...");
	
	BOOL enabled = NO;
	AXBackBoardServer *bbserver = [%c(AXBackBoardServer) server];
	enabled = [bbserver blueLightStatusEnabled];
	DebugLog(@"...NightShift is: %@", enabled?@"on":@"off");
	
	return enabled;
}

static void syncStateWithTriggers() {
	DebugLog(@"syncStateWithTriggers()");
	// Note: only one trigger should be enabled at a time,
	// but we'll handle the edge case where both are enabled just in case.
	
	if (nightShiftControl && !noctisControl) {
		DebugLog(@"syncing to NightShift");
		setDarkMode(nightShiftEnabled());
		
	} else if (noctisControl && !nightShiftControl) {
		DebugLog(@"syncing to Noctis");
		setDarkMode(noctisEnabled());
		
	} else if (nightShiftControl && noctisControl) {
		DebugLog(@"trying to sync to both NightShift and Noctis :S");
		if (nightShiftEnabled() || noctisEnabled()) {
			setDarkMode(YES);
		} else {
			setDarkMode(NO);
		}
	}
}

static void loadSettings() {
	DebugLog(@"loadSettings()");
	
	NSDictionary *settings = nil;
	CFPreferencesAppSynchronize(kPrefsAppID);
	CFArrayRef keyList = CFPreferencesCopyKeyList(kPrefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (keyList) {
		settings = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, kPrefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		DebugLog(@"found user prefs: %@", settings);
		CFRelease(keyList);
	} else {
		DebugLog(@"no user prefs, using defaults");
	}
	
	isEnabled = settings[@"Enabled"] ? [settings[@"Enabled"] boolValue] : YES;
	nightShiftControl = settings[@"NightShiftControl"] ? [settings[@"NightShiftControl"] boolValue] : NO;
	noctisControl = settings[@"NoctisControl"] ? [settings[@"NoctisControl"] boolValue] : NO;
	DebugLog(@"settings >> DarkMode:%@; NightShiftControl:%@; NoctisControl:%@", isEnabled?@"yes":@"no", nightShiftControl?@"yes":@"no", noctisControl?@"yes":@"no");
	
	// sync state with selected trigger(s)
	if (nightShiftControl || noctisControl) {
		syncStateWithTriggers();
	}
}

static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLog(@"*** Notice: %@", name);
	DebugLog(@"handleSettingsChanged() responding");
	
	loadSettings();
}

static void killMobileSMS() {
	DebugLog(@"killing MobileSMS...");
	pid_t pid;
	const char* args[] = { "killall", "MobileSMS", NULL };
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
}

static void handleRelaunchMobileSMS(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLog(@"*** Notice: %@", name);
	DebugLog(@"handleRelaunchMobileSMS() called");
		
	// SpringBoard *sb = (SpringBoard *)[%c(SpringBoard) sharedApplication];
	SBApplicationController *sbac = [%c(SBApplicationController) sharedInstance];
	SBApplication *sbapp = [sbac applicationWithBundleIdentifier:@"com.apple.MobileSMS"];
	
	// 1) suspend MobileSMS before killing it, looks nicer.
	FBUIApplicationService *fbas = [%c(FBUIApplicationService) sharedInstance];
	if (fbas) [sbac applicationService:fbas suspendApplicationWithBundleIdentifier:@"com.apple.MobileSMS"];
	
	// 2) quit MobileSMS
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		killMobileSMS();
		
		// 3) wait a sec, then re-launch MobileSMS
		DebugLog(@"launching MobileSMS...");
		[[%c(SBUIController) sharedInstance] performSelector:@selector(activateApplication:) withObject:sbapp afterDelay:0.5];
		// [[%c(SBUIController) sharedInstance] activateApplication:sbapp];
	});
}


%group NightShift

/* NightShift detection -- for SpringBoard */
%hook CCUIControlCenterStatusUpdate
+ (id)statusUpdateWithString:(id)status reason:(id)reason {
	if (nightShiftControl) {
		DebugLog(@"NightShift update: status=%@ reason=%@", status, reason);
		if ([status hasPrefix:@"Night Shift: On"]) {
			setDarkMode(YES);
		} else if ([status hasPrefix:@"Night Shift: Off"]) {
			setDarkMode(NO);
		}
	}
	return %orig;
}
%end

/* NightShift detection -- for backboardd */
// %hook NightModeControl
// - (void)enableBlueLightReduction:(BOOL)enable withOption:(int)option {
// 	%orig;
// 	if (nightShiftControl) {
// 		if (enable) {
// 			DebugLog(@"night shift on");
// 			setDarkMode(YES);
// 		} else {
// 			DebugLog(@"night shift off");
// 			setDarkMode(NO);
// 		}
// 	}
// %end

%end


%ctor {
	@autoreleasepool {
		DebugLog(@"Loading Helper...");
		
		loadSettings();
		
		// init NightShift hooks
		%init (NightShift);
				
		// init Noctis support (if installed)
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Noctis.dylib"]) {
			DebugLog(@"found Noctis installed, starting listeners");
			
			[[NSNotificationCenter defaultCenter]
				addObserverForName:@"com.laughingquoll.noctis.enablenotification"
				object:nil
				queue:[NSOperationQueue mainQueue]
				usingBlock:^(NSNotification *note) {
					DebugLog(@"*** Notice: Noctis was toggled on");
					if (noctisControl) {
						DebugLog(@"*** Notice: Noctis was toggled on");
						setDarkMode(YES);
					}
				}
			];
			[[NSNotificationCenter defaultCenter]
				addObserverForName:@"com.laughingquoll.noctis.disablenotification"
				object:nil
				queue:[NSOperationQueue mainQueue]
				usingBlock:^(NSNotification *note) {
					DebugLog(@"*** Notice: Noctis was toggled off");
					if (noctisControl) {
						DebugLog(@"*** NoctisControl is on, handling...");
						setDarkMode(NO);
					}
				}
			];
		}
		
		// listen for changes to settings
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)handleSettingsChanged,
			kSettingsChangedNotification,
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
		
		// listen for requests to relaunch MobileSMS
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)handleRelaunchMobileSMS,
			kRelaunchMobileSMSNotification,
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
	}
}

//
//  DarkMessages_SBHelper.xm
//  DarkMessages
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessages_SBHelper]"
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

static BOOL noctisEnabled() {
	DebugLogC(@"Checking Noctis prefs...");
	
	CFPreferencesAppSynchronize(kNoctisAppID);
	Boolean valid;
	Boolean value = CFPreferencesGetAppBooleanValue(kNoctisEnabledKey, kNoctisAppID, &valid);
	BOOL enabled = valid ? value : YES;
	DebugLogC(@"...Noctis is: %@", enabled?@"on":@"off");
	
	return enabled;
}

static BOOL nightShiftEnabled() {
	DebugLogC(@"Checking for NightShift...");
	
	BOOL enabled = NO;
	AXBackBoardServer *bbserver = [%c(AXBackBoardServer) server];
	enabled = [bbserver blueLightStatusEnabled];
	DebugLogC(@"...NightShift is: %@", enabled?@"on":@"off");
	
	return enabled;
}

static void syncStateWithTriggers() {
	DebugLogC(@"syncStateWithTriggers()");
	// Note: only one trigger should be enabled at a time,
	// but we'll handle the edge case where both are enabled just in case.
	
	if (nightShiftControl && !noctisControl) {
		DebugLogC(@"syncing to NightShift");
		setDarkMode(nightShiftEnabled());
		
	} else if (noctisControl && !nightShiftControl) {
		DebugLogC(@"syncing to Noctis");
		setDarkMode(noctisEnabled());
		
	} else if (nightShiftControl && noctisControl) {
		DebugLogC(@"trying to sync to both NightShift and Noctis :S");
		if (nightShiftEnabled() || noctisEnabled()) {
			setDarkMode(YES);
		} else {
			setDarkMode(NO);
		}
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
	
	// sync state with selected trigger(s)
	if (nightShiftControl || noctisControl) {
		syncStateWithTriggers();
	}
}

static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"*** Notice: %@", name);
	loadSettings();
}

static void killMobileSMS() {
	DebugLogC(@"killing MobileSMS...");
	pid_t pid;
	const char* args[] = { "killall", "MobileSMS", NULL };
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
}

static void handleRelaunchMobileSMS(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"*** Notice: %@", name);
	
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
		DebugLogC(@"launching MobileSMS...");
		[[%c(SBUIController) sharedInstance] performSelector:@selector(activateApplication:) withObject:sbapp afterDelay:0.5];
	});
}


%ctor {
	@autoreleasepool {
		DebugLogC(@"Loading SpringBoard helper...");
		
		loadSettings();
		
		// init Noctis support (if installed)
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Noctis.dylib"]) {
			DebugLogC(@"found Noctis installed, starting listeners");
			
			[[NSNotificationCenter defaultCenter]
				addObserverForName:@"com.laughingquoll.noctis.enablenotification"
				object:nil
				queue:[NSOperationQueue mainQueue]
				usingBlock:^(NSNotification *note) {
					DebugLogC(@"*** Notice: Noctis was toggled on");
					if (noctisControl) {
						DebugLogC(@"*** Notice: Noctis was toggled on");
						setDarkMode(YES);
					}
				}
			];
			[[NSNotificationCenter defaultCenter]
				addObserverForName:@"com.laughingquoll.noctis.disablenotification"
				object:nil
				queue:[NSOperationQueue mainQueue]
				usingBlock:^(NSNotification *note) {
					DebugLogC(@"*** Notice: Noctis was toggled off");
					if (noctisControl) {
						DebugLogC(@"*** NoctisControl is on, handling...");
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

//
//  DarkMessages_SB.xm
//  DarkMessages
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessages_SB]"
#import "DebugLog.h"

#import "DarkMessages.h"
#import <spawn.h>


// Function defs
static void setDarkMode(BOOL enabled);
static void loadSettings();
static void applySettings();
static void performSetupForNoctis();
static void syncStateWithTriggers();
static BOOL isNoctisOn();
static BOOL isNightShiftOn();
static void relaunchMessagesApp();
static void closeQR();
static void killProcess(const char *name);


// Global vars
static BOOL isDark;
static BOOL nightShiftControlEnabled;
static BOOL noctisControlEnabled;
static NSString *blueBalloonColor;
static NSString *greenBalloonColor;
static NSString *grayBalloonColor;
static NCNotificationViewController *qrViewController;



// Functions -------------------------------------------------------------------

static void setDarkMode(BOOL enabled) {
	DebugLogC(@"setDarkMode(%@)", enabled ? @"ON" : @"OFF");
	
	// ignore if already in desired mode
	if (enabled == isDark) {
		return;
	}
	
	// update prefs
	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
	settings[@"Enabled"] = [NSNumber numberWithBool:enabled];
	DebugLogC(@"writing new setting: Enabled=%d", [settings[@"Enabled"] boolValue]);
	[settings writeToFile:kPrefsPlistPath atomically:YES];
	
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
	 	kSettingsChangedNotification, NULL, NULL, true);
		
	// isDark = enabled;
}

static void loadSettings() {
	DebugLogC(@"loadSettings()");
	
	NSDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
	
	isDark = settings[@"Enabled"] ? [settings[@"Enabled"] boolValue] : YES;
	nightShiftControlEnabled = settings[@"NightShiftControl"] ? [settings[@"NightShiftControl"] boolValue] : NO;
	noctisControlEnabled = settings[@"NoctisControl"] ? [settings[@"NoctisControl"] boolValue] : NO;
	DebugLogC(@"DarkMode=%@; NightShiftControl=%@; NoctisControl=%@", isDark?@"yes":@"no", nightShiftControlEnabled?@"yes":@"no", noctisControlEnabled?@"yes":@"no");
	
	blueBalloonColor = settings[@"BlueBalloonColor"] ?: @"default";
	greenBalloonColor = settings[@"GreenBalloonColor"] ?: @"default";
	grayBalloonColor = settings[@"GrayBalloonColor"] ?: @"default";
	DebugLogC(@"BlueBalloonColor=%@; GreenBalloonColor=%@; GrayBalloonColor=%@", blueBalloonColor, greenBalloonColor, grayBalloonColor);
}
static void applySettings() {
	DebugLogC(@"applySettings()");
	
	// close the QR popup ...
	DebugLogC(@"**********   Asking QuickReply to quit !!!   **********");
	closeQR();
	
	
	// close Messages...
	DebugLogC(@"**********   Asking Messages to quit !!!   **********");
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
	 	kQuitMessagesNotification, NULL, NULL, true);
}

static void performSetupForNoctis() {
	DebugLogC(@"performSetupForNoctis()");

	[[NSNotificationCenter defaultCenter]
		addObserverForName:@"com.laughingquoll.noctis.enablenotification"
		object:nil
		queue:[NSOperationQueue mainQueue]
		usingBlock:^(NSNotification *note) {
			DebugLogC(@"*** Notice: Noctis was toggled on");

			if (noctisControlEnabled) {
				DebugLogC(@"*** NoctisControl is on, handling...");
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

			if (noctisControlEnabled) {
				DebugLogC(@"*** NoctisControl is on, handling...");
				setDarkMode(NO);
			}
		}
	];
}
static void syncStateWithTriggers() {
	DebugLogC(@"syncStateWithTriggers()");

	// Note: only one trigger should be enabled at a time,
	// but we'll handle the edge case where both are enabled just in case.
	if (nightShiftControlEnabled && !noctisControlEnabled) {
		DebugLogC(@"syncing to NightShift");
		setDarkMode(isNightShiftOn());

	} else if (noctisControlEnabled && !nightShiftControlEnabled) {
		DebugLogC(@"syncing to Noctis");
		setDarkMode(isNoctisOn());

	} else if (nightShiftControlEnabled && noctisControlEnabled) {
		DebugLogC(@"trying to sync to both NightShift and Noctis :S");
		if (isNightShiftOn() || isNoctisOn()) {
			setDarkMode(YES);
		} else {
			setDarkMode(NO);
		}
	} else {
		DebugLogC(@"both NightShift and Noctis are off");
	}
}

static BOOL isNoctisOn() {
	DebugLogC(@"isNoctisOn()");
	
	BOOL on = NO;
	
	CFPreferencesAppSynchronize(kNoctisAppID);
	Boolean valid = NO;
	BOOL value = CFPreferencesGetAppBooleanValue(kNoctisEnabledKey, kNoctisAppID, &valid);
	if (valid) {
		on = value;
	}
	DebugLogC(@"Noctis is: %@", on?@"on":@"off");
	
	return on;
}
static BOOL isNightShiftOn() {
	DebugLogC(@"isNightShiftOn()");
	
	BOOL on = NO;
	
	AXBackBoardServer *bbserver = [%c(AXBackBoardServer) server];
	on = [bbserver blueLightStatusEnabled];
	DebugLogC(@"NightShift is: %@", on?@"on":@"off");
	
	return on;
}

/* Suspend, quit, then relaunch the Messages App. */
static void relaunchMessagesApp() {
	DebugLogC(@"relaunchMessagesApp()");
	
	SBApplicationController *sbac = [%c(SBApplicationController) sharedInstance];
	SBApplication *sbapp = [sbac applicationWithBundleIdentifier:@"com.apple.MobileSMS"];

	// 1) suspend MobileSMS before killing it, looks nicer.
	[sbac applicationService:[%c(FBUIApplicationService) sharedInstance] suspendApplicationWithBundleIdentifier:@"com.apple.MobileSMS"];

	// 2) quit MobileSMS
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		killProcess("MobileSMS");

		// 3) wait a sec, then re-launch MobileSMS
		DebugLogC(@"relaunching MobileSMS...");
		[[%c(SBUIController) sharedInstance] performSelector:@selector(activateApplication:) withObject:sbapp afterDelay:1.0];
	});
}

/* Dismiss, then quit QuickReply. */
static void closeQR() {
	DebugLogC(@"closeQR()");
	
	// close and kill the quick reply extension (it will auto-launch when needed again).
	DebugLogC(@"dismissing QR controller: %@", qrViewController);
	if (qrViewController && [qrViewController respondsToSelector:@selector(dismissPresentedViewControllerAndClearNotification:animated:)]) {
		[qrViewController dismissPresentedViewControllerAndClearNotification:YES animated:YES];
	}
	killProcess("MessagesNotificationExtension");
	killProcess("MessagesNotificationExtension"); // kill with fire
	killProcess("MessagesNotificationExtension"); // die u cruel cruel bastard
}

static void killProcess(const char *name) {
	DebugLogC(@"killProcess(%s)", name);
	
	pid_t pid;
	const char* args[] = { "killall", "-9", name, NULL };
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
}



// Notification Handlers -------------------------------------------------------

static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"*** Notice: %@", name);
	DebugLogC(@"handleSettingsChanged()");
	
	BOOL wasDark = isDark;
	NSString *oldBlue = blueBalloonColor;
	NSString *oldGreen = greenBalloonColor;
	NSString *oldGray = grayBalloonColor;
	
	loadSettings();
	
	// Some settings require Messages/QR to restart if changed...
	
	BOOL needsApply = NO;
	
	if (isDark != wasDark) { // dark mode changed
		needsApply = YES;
	} else if ([blueBalloonColor isEqualToString:oldBlue] == NO) { // color changed
		needsApply = YES;
	} else if ([greenBalloonColor isEqualToString:oldGreen] == NO) { // color changed
		needsApply = YES;
	} else if ([grayBalloonColor isEqualToString:oldGray] == NO) { // color changed
		needsApply = YES;
	}
	
	if (needsApply) {
		DebugLogC(@"### New settings need restart!");
		applySettings();
	} else {
		if (nightShiftControlEnabled || noctisControlEnabled) {
			syncStateWithTriggers();
		}
	}
}

static void handleRelaunchMessagesApp(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"*** Notice: %@", name);
	DebugLogC(@"handleRelaunchMessagesApp()");
	
	relaunchMessagesApp();
}



// Hooks -----------------------------------------------------------------------

@interface SpringBoard (DM)
- (void)_dm_setDarkMode:(BOOL)enabled;
@end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(UIApplication *)application {
	DebugLog0;
	
	%orig;
	
	syncStateWithTriggers();
}
%new
- (void)_dm_setDarkMode:(BOOL)enabled {
	DebugLog0;
	setDarkMode(enabled);
}
%end

// QR host controller
%hook NCNotificationViewController
- (id)initWithNotificationRequest:(NCNotificationRequest *)request {
	DebugLog0;
	
	self = %orig;
	if ([request.sectionIdentifier isEqualToString:@"com.apple.MobileSMS"] && [request.categoryIdentifier isEqualToString:@"MessageExtension"]) {
		qrViewController = self;
		DebugLogC(@"got QuickReply ViewController: %@", qrViewController);
	}
	return self;
}
%end

// Night Shift detection
%hook BrightnessSystemClientExportedObj
- (void)notifyChangedProperty:(NSString *)key value:(NSDictionary *)dict {
    %orig;
    if (nightShiftControlEnabled &&
    	[key isEqualToString:@"CBBlueReductionStatus"] && dict[@"BlueReductionEnabled"]) {
            setDarkMode([dict[@"BlueReductionEnabled"] boolValue]);
    }
}
%end



// Init ------------------------------------------------------------------------

%ctor {
	@autoreleasepool {
		DebugLogC(@"Loaded into SpringBoard");
		
		loadSettings();
		
		// init Noctis support (if installed)
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Noctis.dylib"]) {
			DebugLogC(@"Noctis is installed");
			performSetupForNoctis();
		}
		
		// listen for changes to settings:
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)handleSettingsChanged,
			kSettingsChangedNotification,
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
		
		// listen for requests from Messages to relaunch:
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)handleRelaunchMessagesApp,
			kRelaunchMessagesNotification,
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
	}
}

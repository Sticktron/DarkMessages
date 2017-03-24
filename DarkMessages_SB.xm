//
//  DarkMessages_SB.xm
//  DarkMessages
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessages_SB]"
#import "DebugLog.h"

#import "DarkMessages.h"
#import "DarkMessagesController.h"


static DarkMessagesController *dmc;


static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"*** Notice: %@", name);
	if (dmc) {
		[dmc loadSettings];
		if (dmc.nightShiftControlEnabled || dmc.noctisControlEnabled) {
			[dmc syncStateWithTriggers];
		}
	}
}

static void handleRelaunchMobileSMS(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"*** Notice: %@", name);
	
	SBApplicationController *sbac = [%c(SBApplicationController) sharedInstance];
	SBApplication *sbapp = [sbac applicationWithBundleIdentifier:@"com.apple.MobileSMS"];
	
	// 1) suspend MobileSMS before killing it, looks nicer.
	FBUIApplicationService *fbas = [%c(FBUIApplicationService) sharedInstance];
	if (fbas) [sbac applicationService:fbas suspendApplicationWithBundleIdentifier:@"com.apple.MobileSMS"];
	
	// 2) quit MobileSMS
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		[dmc killMobileSMS];
		
		// 3) wait a sec, then re-launch MobileSMS
		DebugLogC(@"launching MobileSMS...");
		[[%c(SBUIController) sharedInstance] performSelector:@selector(activateApplication:) withObject:sbapp afterDelay:0.666];
	});
}


//------------------------------------------------------------------------------


%hook SpringBoard
- (void)applicationDidFinishLaunching:(UIApplication *)application {
	%orig;
	// sync state with selected trigger(s)
	if (dmc.nightShiftControlEnabled || dmc.noctisControlEnabled) {
		[dmc syncStateWithTriggers];
	}
}
%end

%hook NCNotificationViewController
- (id)initWithNotificationRequest:(NCNotificationRequest *)request {
	// DebugLogC(@"##########  initWithNotificationRequest  ##########");
	// DebugLogC(@"sectionID = %@", [request sectionIdentifier]);
	// DebugLogC(@"categoryID = %@", [request categoryIdentifier]);

	self = %orig;

	if ([request.sectionIdentifier isEqualToString:@"com.apple.MobileSMS"] && [request.categoryIdentifier isEqualToString:@"MessageExtension"]) {
		dmc.qrViewController = self;
		DebugLogC(@"got QuickReply ViewController: %@", dmc.qrViewController);
	}

	return self;
}
%end

%hook CBBlueLightClient
- (BOOL)setEnabled:(BOOL)enabled {
	if (dmc && dmc.nightShiftControlEnabled) {
		BOOL result = %orig;		
		DebugLog(@"BL turning %@", enabled?@"ON":@"OFF");
		DebugLog(@"result = %d", result);
		
		[dmc setDarkMode:enabled];
		
		return result;
	} else {
		return %orig;
	}
	
}
- (BOOL)setEnabled:(BOOL)enabled withOption:(int)option {
	if (dmc && dmc.nightShiftControlEnabled) {
		BOOL result = %orig;
		DebugLog(@"BL turning %@ (with option: %d)", enabled?@"ON":@"OFF", option);
		DebugLog(@"result = %d", result);
		
		[dmc setDarkMode:enabled];
		
		return result;
	} else {
		return %orig;
	}
}
%end


//------------------------------------------------------------------------------


%ctor {
	@autoreleasepool {
		DebugLogC(@"Loaded into SpringBoard");
		
		// create main controller
		dmc = [[DarkMessagesController alloc] init];
		
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

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


@interface NCNotificationRequest : NSObject
@property (nonatomic, readonly, copy) NSString *sectionIdentifier;
@property (nonatomic, readonly, copy) NSString *categoryIdentifier;
@end


@interface NCNotificationViewController : UIViewController
- (id)initWithNotificationRequest:(NCNotificationRequest *)arg1;
- (BOOL)dismissPresentedViewControllerAndClearNotification:(BOOL)arg1 animated:(BOOL)arg2;
- (void)dismissViewControllerWithTransition:(int)arg1 completion:(id /* block */)arg2;
@end


@interface DarkMessagesController : NSObject
@property (nonatomic, readonly) BOOL isDark;
@property (nonatomic) BOOL nightShiftControlEnabled;
@property (nonatomic) BOOL noctisControlEnabled;
@end


static DarkMessagesController *dmc;


@interface DarkMessagesController ()
@property (nonatomic) BOOL isDark;
@property (nonatomic, strong) NCNotificationViewController *qrViewController;
@end

@implementation DarkMessagesController
- (instancetype)init {
	if (self = [super init]) {
		DebugLog0;
		
		[self loadSettings];
		
		// init Noctis support (if installed)
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Noctis.dylib"]) {
			DebugLogC(@"found Noctis installed, starting listeners");
			
			[[NSNotificationCenter defaultCenter]
				addObserverForName:@"com.laughingquoll.noctis.enablenotification"
				object:nil
				queue:[NSOperationQueue mainQueue]
				usingBlock:^(NSNotification *note) {
					DebugLogC(@"*** Notice: Noctis was toggled on");
					if (self.noctisControlEnabled) {
						DebugLogC(@"*** NoctisControl is on, handling...");
						[self setDarkMode:YES];
					}
				}];
			
			[[NSNotificationCenter defaultCenter]
				addObserverForName:@"com.laughingquoll.noctis.disablenotification"
				object:nil
				queue:[NSOperationQueue mainQueue]
				usingBlock:^(NSNotification *note) {
					DebugLogC(@"*** Notice: Noctis was toggled off");
					if (self.noctisControlEnabled) {
						DebugLogC(@"*** NoctisControl is on, handling...");
						[self setDarkMode:NO];
					}
				}];
		}
	}
	return self;
}
- (void)loadSettings {
	DebugLog0;
	
	NSDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
	self.isDark = settings[@"Enabled"] ? [settings[@"Enabled"] boolValue] : YES;
	self.nightShiftControlEnabled = settings[@"NightShiftControl"] ? [settings[@"NightShiftControl"] boolValue] : NO;
	self.noctisControlEnabled = settings[@"NoctisControl"] ? [settings[@"NoctisControl"] boolValue] : NO;
	DebugLog(@"settings >> DarkMode:%@; NightShiftControl:%@; NoctisControl:%@", self.isDark?@"yes":@"no", self.nightShiftControlEnabled?@"yes":@"no", self.noctisControlEnabled?@"yes":@"no");
}
- (void)setDarkMode:(BOOL)enabled {
	DebugLog(@"setting to: %@", enabled ? @"yes" : @"no");
	
	// only set if different than current mode
	if (self.isDark != enabled) {
		self.isDark = enabled;
		DebugLogC(@"Dark Mode changed to: %d", self.isDark);
		
		// update prefs
		NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
		settings[@"Enabled"] = self.isDark ? @YES : @NO;
		[settings writeToFile:kPrefsPlistPath atomically:YES];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
			kSettingsChangedNotification, NULL, NULL, true
		);
		
		// deal with quick reply extension
		DebugLogC(@"dismiss QR controller: %@", self.qrViewController);
		if (self.qrViewController && [self.qrViewController respondsToSelector:@selector(dismissPresentedViewControllerAndClearNotification:animated:)]) {
			[self.qrViewController dismissPresentedViewControllerAndClearNotification:YES animated:YES];
			[self killQR];
		}
	} else {
		DebugLogC(@"already in mode (%@)", enabled?@"ON":@"OFF");
	}
}
- (void)syncStateWithTriggers {
	// Note: only one trigger should be enabled at a time,
	// but we'll handle the edge case where both are enabled just in case.
	if (self.nightShiftControlEnabled && !self.noctisControlEnabled) {
		DebugLog(@"syncing to NightShift");
		[self setDarkMode:[self isNightShiftOn]];
		
	} else if (self.noctisControlEnabled && !self.nightShiftControlEnabled) {
		DebugLog(@"syncing to Noctis");
		[self setDarkMode:[self isNoctisOn]];
		
	} else if (self.nightShiftControlEnabled && self.noctisControlEnabled) {
		DebugLog(@"trying to sync to both NightShift and Noctis :S");
		if ([self isNightShiftOn] || [self isNoctisOn]) {
			[self setDarkMode:YES];
		} else {
			[self setDarkMode:NO];
		}
	}
}
- (BOOL)isNoctisOn {
	DebugLog0;
	BOOL on = YES;
	
	CFPreferencesAppSynchronize(kNoctisAppID);
	Boolean valid = NO;
	BOOL value = CFPreferencesGetAppBooleanValue(kNoctisEnabledKey, kNoctisAppID, &valid);
	if (valid) {
		on = value;
	}
	DebugLog(@"Noctis is: %@", on?@"on":@"off");
	
	return on;
}
- (BOOL)isNightShiftOn {
	DebugLog0;
	
	AXBackBoardServer *bbserver = [%c(AXBackBoardServer) server];
	BOOL on = [bbserver blueLightStatusEnabled];
	DebugLog(@"NightShift is: %@", on?@"on":@"off");
	
	return on;
}
- (void)killMobileSMS {
	DebugLog0;
	
	pid_t pid;
	const char* args[] = { "killall", "-HUP", "MobileSMS", NULL };
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
}
- (void)killQR {
	DebugLog0;
	
	pid_t pid;
	const char* args[] = { "killall", "-9", "MessagesNotificationExtension", NULL };
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
}
@end


static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLogC(@"*** Notice: %@", name);
	
	if (dmc) {
		[dmc loadSettings];
		
		// sync state with selected trigger(s)
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


%hook SpringBoard
- (void)applicationDidFinishLaunching:(UIApplication *)application {
	%orig;
	// sync state with selected trigger(s)
	if (dmc.nightShiftControlEnabled || dmc.noctisControlEnabled) {
		[dmc syncStateWithTriggers];
	}
}
%end


//------------------------------------------------------------------------------
%hook NCNotificationViewController
- (id)initWithNotificationRequest:(NCNotificationRequest *)request {
	DebugLogC(@"##########  initWithNotificationRequest  ##########");
	DebugLogC(@"sectionID = %@", [request sectionIdentifier]);
	DebugLogC(@"categoryID = %@", [request categoryIdentifier]);

	self = %orig;

	if ([request.sectionIdentifier isEqualToString:@"com.apple.MobileSMS"] && [request.categoryIdentifier isEqualToString:@"MessageExtension"]) {
		dmc.qrViewController = self;
		DebugLogC(@"QuickReply viewController = %@", dmc.qrViewController);
	}

	return self;
}
%end
//------------------------------------------------------------------------------


%ctor {
	@autoreleasepool {
		DebugLogC(@"Loading SpringBoard helper...");
		
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

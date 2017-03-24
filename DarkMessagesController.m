//
//  DarkMessagesController.m
//  DarkMessages
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessagesController]"
#import "DebugLog.h"


#import "DarkMessagesController.h"
#import "DarkMessages.h"
#import <spawn.h>


@interface DarkMessagesController ()
@property (nonatomic) BOOL isDark;
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
	NSDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
	self.isDark = settings[@"Enabled"] ? [settings[@"Enabled"] boolValue] : YES;
	self.nightShiftControlEnabled = settings[@"NightShiftControl"] ? [settings[@"NightShiftControl"] boolValue] : NO;
	self.noctisControlEnabled = settings[@"NoctisControl"] ? [settings[@"NoctisControl"] boolValue] : NO;
	DebugLog(@"DarkMode=%@; NightShiftControl=%@; NoctisControl=%@", self.isDark?@"yes":@"no", self.nightShiftControlEnabled?@"yes":@"no", self.noctisControlEnabled?@"yes":@"no");
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
		
		// deal with quick reply extension
		DebugLogC(@"dismiss QR controller: %@", self.qrViewController);
		if (self.qrViewController && [self.qrViewController respondsToSelector:@selector(dismissPresentedViewControllerAndClearNotification:animated:)]) {
			[self.qrViewController dismissPresentedViewControllerAndClearNotification:YES animated:YES];
		}
		[self killQR];
		[self killQR]; // kill with fire
		[self killQR]; // die u cruel, cruel bastard
		
		// notify that prefs have changed
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
			kSettingsChangedNotification, NULL, NULL, true
		);
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
	
	AXBackBoardServer *bbserver = [NSClassFromString(@"AXBackBoardServer") server];
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

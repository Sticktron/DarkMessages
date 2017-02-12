//
//  DarkMessages.h
//  DarkMessages
//
//  ©2017 Sticktron
//

#define kPrefsAppID 		CFSTR("com.sticktron.darkmessages")
#define kPrefsEnabledKey 	CFSTR("Enabled")

#define kNoctisAppID 		CFSTR("com.laughingquoll.noctis")
#define kNoctisEnabledKey 	CFSTR("LQDDarkModeEnabled")

#define kSettingsChangedNotification 	CFSTR("com.sticktron.darkmessages.settingschanged")
#define kRelaunchMobileSMSNotification 	CFSTR("com.sticktron.darkmessages.relaunchmobilesms")

// Private APIs

@interface UIApplication (DM)
- (BOOL)isSuspended;
- (void)terminateWithSuccess;
@end

@interface UIWindow (DM)
+ (id)keyWindow;
@end

@interface CKUITheme : NSObject
@end

@interface CKUIThemeDark : CKUITheme
- (UIColor *)entryFieldButtonColor;
- (UIColor *)entryFieldDarkStyleButtonColor;
@end

@interface AXBackBoardServer : NSObject
+ (id)server;
- (BOOL)blueLightStatusEnabled;
@end

@interface SpringBoard : NSObject
- (BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
- (void)_simulateHomeButtonPress;
- (void)_simulateHomeButtonPressWithCompletion:(id /*block*/)arg1;
- (id)_accessibilityFrontMostApplication;
@end

@interface SBApplication : NSObject
- (id)bundleIdentifier;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)applicationWithBundleIdentifier:(id)arg1;
- (void)applicationService:(id)arg1 suspendApplicationWithBundleIdentifier:(id)arg2;
- (void)applicationService:(id)arg1 setNextWakeDate:(id)arg2 forBundleIdentifier:(id)arg3;
@end

@interface SBUIController : NSObject
+ (id)sharedInstanceIfExists;
- (void)activateApplication:(id)arg1;
@end

@interface FBUIApplicationService : NSObject
+ (id)sharedInstance;
@end

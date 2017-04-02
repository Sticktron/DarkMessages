//
//  DarkMessages.h
//  DarkMessages
//
//  ©2017 Sticktron
//

#define kPrefsPlistPath 		@"/var/mobile/Library/Preferences/com.sticktron.darkmessages.plist"

#define kNoctisAppID 			CFSTR("com.laughingquoll.noctis")
#define kNoctisEnabledKey 		CFSTR("LQDDarkModeEnabled")

#define kSettingsChangedNotification		CFSTR("com.sticktron.darkmessages.settings-changed")
#define kQuitMessagesNotification 			CFSTR("com.sticktron.darkmessages.please-quit-messages")
#define kRelaunchMessagesNotification 		CFSTR("com.sticktron.darkmessages.please-relaunch-messages")


// Private APIs

@interface SpringBoard : UIApplication
- (id)_accessibilityFrontMostApplication;
@end

@interface UIApplication (DM)
- (BOOL)isSuspended;
- (void)terminateWithSuccess;
@end

@interface UIImage (DM)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

@interface CKUITheme : NSObject
@end

@interface CKUIThemeDark : CKUITheme
- (UIColor *)entryFieldButtonColor;
- (UIColor *)entryFieldDarkStyleButtonColor;
@end

@interface NightModeControl : NSObject // from CoreBrightness
- (void)enableBlueLightReduction:(BOOL)arg1 withOption:(int)arg2;
@end

@interface CBBlueLightClient : NSObject
+ (BOOL)supportsBlueLightReduction;
- (BOOL)setEnabled:(BOOL)arg1;
- (BOOL)setEnabled:(BOOL)arg1 withOption:(int)arg2;
@end

@interface AXBackBoardServer : NSObject
+ (id)server;
- (BOOL)blueLightStatusEnabled;
@end

@interface SBApplication : NSObject
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)applicationWithBundleIdentifier:(id)arg1;
- (void)applicationService:(id)arg1 suspendApplicationWithBundleIdentifier:(id)arg2;
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic, readonly, copy) NSString *sectionIdentifier;
@property (nonatomic, readonly, copy) NSString *categoryIdentifier;
@end

@interface NCNotificationViewController : UIViewController
- (id)initWithNotificationRequest:(NCNotificationRequest *)arg1;
- (BOOL)dismissPresentedViewControllerAndClearNotification:(BOOL)arg1 animated:(BOOL)arg2;
- (void)dismissViewControllerWithTransition:(int)arg1 completion:(id /* block */)arg2;
@end

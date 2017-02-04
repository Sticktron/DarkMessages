//
//  DarkMessages
//  Dark theme for Messages app.
//  iOS 10
//
//  @sticktron
//

#define DEBUG_PREFIX @"[DarkMessages]"
#import "DebugLog.h"

#import "Headers.h"
// #import <spawn.h>


CFStringRef kPrefsAppID = CFSTR("com.sticktron.darkmessages");
CFStringRef kEnabledKey = CFSTR("Enabled");
CFStringRef kNoctisSyncKey = CFSTR("NoctisSync");

CFStringRef kSettingsChangedID = CFSTR("com.sticktron.darkmessages.settingschanged");
CFStringRef kNoctisEnabledID = CFSTR("com.sticktron.darkmessages.noctisenabled");
CFStringRef kNoctisDisabledID = CFSTR("com.sticktron.darkmessages.noctisdisabled");

// CFStringRef kNoctisAppID = CFSTR("com.laughingquoll.noctisprefs.plist ");
// CFStringRef kNoctisEnabledKey = CFSTR("enabled");
CFStringRef kNoctisAppID = CFSTR("com.laughingquoll.noctis");
CFStringRef kNoctisEnabledKey = CFSTR("LQDDarkModeEnabled");

static BOOL isEnabled;
static CKUIThemeDark *darkTheme;


static void killMessages() {
	NSLog(@"DarkMessages >> Terminating MobileSMS...");
	
	[[UIApplication sharedApplication] terminateWithSuccess];
	
	// pid_t pid;
	// const char* args[] = { "killall", "MobileSMS", NULL };
	// posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
}

static void loadSettings() {
	CFPreferencesAppSynchronize(kPrefsAppID);
	Boolean valid;
	Boolean value = CFPreferencesGetAppBooleanValue(kEnabledKey, kPrefsAppID, &valid);
	isEnabled = valid ? (BOOL)value : YES;
	DebugLog(@"Loaded settings >> is enabled? %@", isEnabled?@"yes":@"no");
}

static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLog(@"Notice: Preferences have changed!");
	BOOL oldSetting = isEnabled;
	loadSettings();
	if (isEnabled != oldSetting) {
		killMessages();
	}
}

// SpringBoard-only function
static void handleNoctis(BOOL didEnable) {
	DebugLog(@"Noctis was toggled: %@", didEnable?@"ON":@"OFF");
	CFPreferencesSetAppValue(kEnabledKey, didEnable ? kCFBooleanTrue : kCFBooleanFalse, kPrefsAppID);
	CFPreferencesAppSynchronize(kPrefsAppID);
	
	// tell MobileSMS
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kSettingsChangedID, NULL, NULL, true);
}


// MobileSMS Hooks -------------------------------------------------------------

%group Phone
%hook CKUIBehaviorPhone
- (id)theme {
	// return isEnabled ? darkTheme : %orig;
	return darkTheme;
}
%end
%end

//------------------------------------------------------------------------------

%group Pad
%hook CKUIBehaviorPad
- (id)theme {
	// return isEnabled ? darkTheme : %orig;
	return darkTheme;
}
%end
%end

//------------------------------------------------------------------------------

%group Common

// fix navbar: style
%hook CKAvatarNavigationBar
- (void)_setBarStyle:(int)style {
	// isEnabled ? %orig(1) : %orig;
	%orig(1);
}
%end

// fix navbar: contact names
%hook CKAvatarContactNameCollectionReusableView
- (void)setStyle:(int)style {
	// isEnabled ? %orig(3) : %orig;
	%orig(3);
}
%end

// fix navbar: group names
%hook CKAvatarTitleCollectionReusableView
- (void)setStyle:(int)style {
	// isEnabled ? %orig(3) : %orig;
	%orig(3);
}
%end

// fix navbar: new message label
%hook CKNavigationBarCanvasView
- (id)titleView {
	// if (isEnabled) {
		id tv = %orig;
		if (tv && [tv respondsToSelector:@selector(setTextColor:)]) {
			[(UILabel *)tv setTextColor:UIColor.whiteColor];
		}
		return tv;
	// } else {
	// 	return %orig;
	// }
}
%end

// fix group details: contact names
%hook CKDetailsContactsTableViewCell
- (UILabel *)nameLabel {
	// if (isEnabled) {
		UILabel *nl = %orig;
		nl.textColor = UIColor.whiteColor;
		return nl;
	// } else {
	// 	return %orig;
	// }
}
%end

%end

//------------------------------------------------------------------------------

%ctor {
	@autoreleasepool {
		
		if (IN_SPRINGBOARD == NO) { // init for MobileSMS ...
			loadSettings();
			
			if (isEnabled) {
				darkTheme = [[%c(CKUIThemeDark) alloc] init];
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
					%init(Pad);
				} else {
					%init(Phone);
				}
				%init(Common);
			}
			
			// listen for settings changes
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
				NULL,
				(CFNotificationCallback)handleSettingsChanged,
				kSettingsChangedID,
				NULL,
				CFNotificationSuspensionBehaviorDeliverImmediately
			);

		} else { // init for SpringBoard ...
			
			// skip if Noctis isn't installed
			if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Noctis.dylib"]) {
				return;
			}
			
			// is NoctisSync enabled?
			CFPreferencesAppSynchronize(kPrefsAppID);
			Boolean valid;
			Boolean value = CFPreferencesGetAppBooleanValue(kNoctisSyncKey, kPrefsAppID, &valid);
			BOOL noctisSync = valid ? (BOOL)value : YES;
			DebugLog(@"NoctisSync enabled? %@", noctisSync?@"yes":@"no");
			
			if (noctisSync) {
				// sync Noctis' settings with ours
				CFPreferencesAppSynchronize(kNoctisAppID);
				Boolean valid;
				Boolean value = CFPreferencesGetAppBooleanValue(kNoctisEnabledKey, kNoctisAppID, &valid);
				DebugLog(@"Checking Noctis prefs, key is valid? %@", valid?@"yes":@"no");
				DebugLog(@"Checking Noctis prefs, value is? %@", value?@"yes":@"no");
				BOOL noctisEnabled = valid ? (BOOL)value : YES;
				DebugLog(@"Noctis enabled? %@", noctisEnabled?@"yes":@"no");
				handleNoctis(noctisEnabled);
				
				// listen for notifications
				[[NSNotificationCenter defaultCenter]
					addObserverForName:@"com.laughingquoll.noctis.enablenotification"
					object:nil
					queue:[NSOperationQueue mainQueue]
					usingBlock:^(NSNotification *note) {
						DebugLog(@"Notice: Noctis has been enabled!");
						handleNoctis(YES);
					}
				];
				[[NSNotificationCenter defaultCenter]
					addObserverForName:@"com.laughingquoll.noctis.disablenotification"
					object:nil
					queue:[NSOperationQueue mainQueue]
					usingBlock:^(NSNotification *note) {
						DebugLog(@"Notice: Noctis has been disabled!");
						handleNoctis(NO);
					}
				];
			}
		}
	}
}

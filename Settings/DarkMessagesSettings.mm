//
//  Settings for DarkMessages
//
//  ©2017 Sticktron
//

#define DEBUG_PREFIX @"[DarkMessagesSettings]"
#import "../DebugLog.h"

#import "../DarkMessages.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import <spawn.h>

#define TINT_COLOR 			[UIColor colorWithWhite:0.25 alpha:1] //#404040
#define LINK_COLOR			[UIColor blackColor]
#define BLUE_TINT_COLOR		[UIColor colorWithRed:15/255.0 green:132/255.0 blue:252/255.0 alpha:1] //#0F84FC
#define HEADER_HEIGHT 		120.0

static PSListController *controller;

static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLog(@"Notice: %@", name);
	[controller reloadSpecifierID:@"Enabled" animated:YES];
}


@interface DarkMessagesSettingsController : PSListController
@end

@implementation DarkMessagesSettingsController
- (instancetype)init {
	if (self = [super init]) {
		controller = self;
		
		// listen for changes from helper (to update the Dark Mode switch)
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)handleSettingsChanged,
			kSettingsChangedNotification,
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
	}
	return self;
}
- (id)specifiers {
	if (_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"DarkMessages" target:self];
		
		// disable Noctis Control switch if Noctis is not installed
		BOOL hasNoctis = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Noctis.dylib"];
		if (!hasNoctis) {
			PSSpecifier *specifier = [self specifierForID:@"NoctisControl"];
			[specifier setProperty:@NO forKey:@"enabled"];
			[specifier setProperty:@NO forKey:@"default"];
		}
	}
	return _specifiers;
}
- (void)setNoctisControlValue:(id)value specifier:(id)specifier {
	[super setPreferenceValue:value specifier:specifier];
	
	if ([value boolValue]) {
		PSSpecifier *spec = [self specifierForID:@"NightShiftControl"];
		[self setPreferenceValue:@NO specifier:spec];
		[self reloadSpecifier:spec animated:YES];
	}
	
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kSettingsChangedNotification, NULL, NULL, YES);
}
- (void)setNightShiftControlValue:(id)value specifier:(id)specifier {
	[super setPreferenceValue:value specifier:specifier];
	
	if ([value boolValue]) {
		PSSpecifier *spec = [self specifierForID:@"NoctisControl"];
		[self setPreferenceValue:@NO specifier:spec];
		[self reloadSpecifier:spec animated:YES];
	}
	
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kSettingsChangedNotification, NULL, NULL, YES);
}
- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = nil;
	
	
	// add a heart button to the navbar
	UIImage *heartImage = [[UIImage alloc] initWithContentsOfFile:@"/Library/PreferenceBundles/DarkMessages.bundle/heart.png"];
	UIBarButtonItem *heartButton = [[UIBarButtonItem alloc] initWithImage:heartImage style:UIBarButtonItemStylePlain target:self action:@selector(showLove)];
	heartButton.imageInsets = (UIEdgeInsets){2, 0, -2, 0};
	heartButton.tintColor = TINT_COLOR;
	[self.navigationItem setRightBarButtonItem:heartButton];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	// tint navbar
	self.navigationController.navigationController.navigationBar.tintColor = TINT_COLOR;
}
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	// un-tint navbar
	self.navigationController.navigationController.navigationBar.tintColor = nil;
}
- (CGFloat)tableView:(id)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return HEADER_HEIGHT;
	} else {
		return [super tableView:tableView heightForHeaderInSection:section];
	}
}
- (id)tableView:(id)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		// add table header
		UIImage *logoImage = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DarkMessages.bundle/header.png"];
		UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, HEADER_HEIGHT)];
		logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		logoView.image = logoImage;
		UIView *headerView = [[UIView alloc] initWithFrame:logoView.frame];
		headerView.backgroundColor = [UIColor colorWithWhite:0.09 alpha:1]; //#171717
		[headerView addSubview:logoView];
		return headerView;
	} else {
		return [super tableView:tableView viewForHeaderInSection:section];
	}
}
- (void)openEmail {
	NSString *subject = @"DarkMessages Support";
	NSString *body = @"";
	NSString *urlString = [NSString stringWithFormat:@"mailto:sticktron@hotmail.com?subject=%@&body=%@", subject, body];
	NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
	[[UIApplication sharedApplication] openURL:url];
}
- (void)openTwitter {
	NSURL *url;
	
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		url = [NSURL URLWithString:@"tweetbot:///user_profile/sticktron"];
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
		url = [NSURL URLWithString:@"twitterrific:///profile?screen_name=sticktron"];
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
		url = [NSURL URLWithString:@"tweetings:///user?screen_name=sticktron"];
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		url = [NSURL URLWithString:@"twitter://user?screen_name=sticktron"];
	} else {
		url = [NSURL URLWithString:@"http://twitter.com/sticktron"];
	}
		
	[[UIApplication sharedApplication] openURL:url];
}
- (void)openGitHub {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/sticktron/darkmessages"]];
}
- (void)openGitHubIssue {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/sticktron/darkmessages/issues"]];
}
- (void)openReddit {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://reddit.com/r/jailbreak/"]];
}
- (void)showLove {
	NSString *url = @"https://paypal.com/cgi-bin/webscr?cmd=_donations&business=BKGYMJNGXM424&lc=CA&item_name=Donation%20to%20Sticktron&item_number=DarkMessages&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted";
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
// - (void)respring {
// 	pid_t pid;
// 	const char* args[] = { "killall", "-9", "backboardd", NULL };
// 	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
// }
@end


// Custom Table Cells ----------------------------------------------------------

@interface DMLinkCell : PSTableCell
@end

@implementation DMLinkCell
- (void)layoutSubviews {
	[super layoutSubviews];
	[self setTintColor:BLUE_TINT_COLOR];
	[self.textLabel setTextColor:LINK_COLOR];
}
@end

//------------------------------------------------------------------------------

@interface DMButtonCell : PSTableCell
@end

@implementation DMButtonCell
- (void)layoutSubviews {
	[super layoutSubviews];
	[self.textLabel setTextColor:BLUE_TINT_COLOR];
}
@end

//------------------------------------------------------------------------------

@interface DMSwitchCell : PSSwitchTableCell
@end
@implementation DMSwitchCell
- (id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	if (self) {
		[((UISwitch *)[self control]) setOnTintColor:BLUE_TINT_COLOR];
	}
	return self;
}
@end

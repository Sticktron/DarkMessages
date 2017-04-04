//
//  Settings for DarkMessages
//
//  ©2017 Sticktron
//

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import <spawn.h>

#import "../DarkMessages.h"
#import "DarkMessagesColorPicker.h"
#import "../UIColor-Additions.h"
#import "DarkMessagesTheme.h"


#define VERSION_STRING	@"v1.2.0"

static PSListController *controller;
static float headerHeight = 140.0f;


static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[controller reloadSpecifierID:@"Enabled" animated:YES];
}



// Settings Controller ---------------------------------------------------------

@interface DarkMessagesSettingsController : PSListController
@property (nonatomic, strong) UIView *headerView;
@end

@implementation DarkMessagesSettingsController
- (instancetype)init {
	if (self = [super init]) {
		
		[DarkMessagesTheme themeStuffInClasses:@[ self.class ]];
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)handleSettingsChanged,
			kSettingsChangedNotification,
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
	}
	controller = self;
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
- (void)viewDidLoad {
	[super viewDidLoad];
	
	// use icon instead of title text
	UIImage *icon = [UIImage imageNamed:@"icon.png" inBundle:self.bundle];
	self.navigationItem.titleView = [[UIImageView alloc] initWithImage:icon];
	
	// add twitter button to the navbar
	UIImage *birdImage = [UIImage imageNamed:@"twitter.png" inBundle:self.bundle];
	UIBarButtonItem *birdButton = [[UIBarButtonItem alloc] initWithImage:birdImage style:UIBarButtonItemStylePlain target:self action:@selector(openTwitter)];
	birdButton.imageInsets = (UIEdgeInsets){2, 0, 0, 0};
	[self.navigationItem setRightBarButtonItem:birdButton];
}

/* Tint navbar items. */
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// tint navbar
	self.navigationController.navigationController.navigationBar.tintColor = [DarkMessagesTheme tintColor];
}
- (void)viewWillDisappear:(BOOL)animated {
	// un-tint navbar
	self.navigationController.navigationController.navigationBar.tintColor = nil;
	
	[super viewWillDisappear:animated];
}

/* TableView stuff. */
- (id)tableView:(id)tableView viewForHeaderInSection:(NSInteger)section {
	if (section != 0) {
		return [super tableView:tableView viewForHeaderInSection:section];
	}
	
	if (!self.headerView) {
		
		UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, headerHeight)];
		headerView.backgroundColor = [DarkMessagesTheme bgColor];
		headerView.opaque = YES;
		
		CGRect frame = CGRectMake(15, 47, headerView.bounds.size.width, 50);
		UILabel *tweakTitle = [[UILabel alloc] initWithFrame:frame];
		tweakTitle.text = @"DarkMessages";
		tweakTitle.font = [UIFont systemFontOfSize:40 weight:UIFontWeightThin];
		tweakTitle.textColor = UIColor.whiteColor;
		tweakTitle.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:tweakTitle];
		
		CGRect subtitleFrame = CGRectMake(15, 94, headerView.bounds.size.width, 20);
		UILabel *tweakSubtitle = [[UILabel alloc] initWithFrame:subtitleFrame];
		tweakSubtitle.text = VERSION_STRING;
		tweakSubtitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightThin];
		tweakSubtitle.textColor = [DarkMessagesTheme footerTextColor];
		tweakSubtitle.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:tweakSubtitle];
		
		self.headerView = headerView;
	}
	
	return self.headerView;
}
- (CGFloat)tableView:(id)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return headerHeight;
	} else {
		return [super tableView:tableView heightForHeaderInSection:section];
	}
}

/* Old-school prefs. */
- (id)readPreferenceValue:(PSSpecifier *)specifier {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
	if (!settings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return settings[specifier.properties[@"key"]];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kPrefsPlistPath]];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:kPrefsPlistPath atomically:YES];

	CFStringRef notificationValue = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationValue) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationValue, NULL, NULL, YES);
	}
}

/* Allow only one control method to be enabled at once. */
- (void)setNoctisControlValue:(id)value specifier:(id)specifier {
	if ([value boolValue] == YES) {
		// turn off NightShift control switch
		PSSpecifier *spec = [self specifierForID:@"NightShiftControl"];
		[self setPreferenceValue:@NO specifier:spec];
		[self reloadSpecifier:spec animated:YES];
	}
	
	// save value
	[self setPreferenceValue:value specifier:specifier];
}
- (void)setNightShiftControlValue:(id)value specifier:(id)specifier {
	if ([value boolValue] == YES) {
		// turn off Noctis control switch
		PSSpecifier *spec = [self specifierForID:@"NoctisControl"];
		[self setPreferenceValue:@NO specifier:spec];
		[self reloadSpecifier:spec animated:YES];
	}
	
	// save value
	[self setPreferenceValue:value specifier:specifier];
}

/* Buttons */
- (void)openGitHubIssue {
	NSURL *url = [NSURL URLWithString:@"http://github.com/sticktron/darkmessages/issues"];
	// [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
	[[UIApplication sharedApplication] openURL:url];
}
- (void)openEmail {
	NSString *subject = @"DarkMessages Support";
	NSString *body = @"";
	NSString *urlString = [NSString stringWithFormat:@"mailto:sticktron@hotmail.com?subject=%@&body=%@", subject, body];
	NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
	// [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
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
		
	// [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
	[[UIApplication sharedApplication] openURL:url];
}
- (void)openPayPal {
	NSURL *url = [NSURL URLWithString:@"https://paypal.com/cgi-bin/webscr?cmd=_donations&business=BKGYMJNGXM424&lc=CA&item_name=Donation%20to%20Sticktron&item_number=DarkMessages&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted"];
	// [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
	[[UIApplication sharedApplication] openURL:url];
}
@end



// Custom Switch Cell ----------------------------------------------------------

@interface DMSwitchCell : PSSwitchTableCell
@end

@implementation DMSwitchCell
- (id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	if (self) {
		[self.textLabel setTextColor:[DarkMessagesTheme cellTextColor]];
		self.separatorInset = UIEdgeInsetsZero;
	}
	return self;
}
@end



// Custom Link Cell ------------------------------------------------------------

@interface PSTableCell (DM)
- (id)_disclosureChevronImage:(BOOL)arg1;
@end

@interface DMLinkCell : PSTableCell
@end

@implementation DMLinkCell
- (id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	if (self) {
		[self.textLabel setTextColor:[DarkMessagesTheme cellTextColor]];
		self.separatorInset = UIEdgeInsetsZero;
	}
	return self;
}
- (id)_disclosureChevronImage:(BOOL)arg1 {
	// make it tintable
	UIImage *chev = [super _disclosureChevronImage:arg1];
	chev = [chev imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	return chev;
}
@end



// Color Picker Link Cell ------------------------------------------------------

@interface DMColorPickerLinkCell : DMLinkCell
@property (nonatomic, strong) NSString *selectedColor;
@property (nonatomic, strong) UIImageView *thumbnailView;
@end

@implementation DMColorPickerLinkCell
- (id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	if (self) {
		_thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
		_thumbnailView.layer.cornerRadius = 4;
		_thumbnailView.layer.masksToBounds = YES;
		[self.contentView addSubview:_thumbnailView];
	}
	return self;
}
- (void)layoutSubviews {
	[super layoutSubviews];
	
	// position thumbnail (TODO handle RTL orientation)
	self.thumbnailView.center = self.contentView.center;
	CGRect thumbFrame = self.thumbnailView.frame;
	thumbFrame.origin.x = self.contentView.bounds.size.width - thumbFrame.size.width - 4;
	self.thumbnailView.frame = thumbFrame;
	
	// read selected color from prefs
	NSString *key = [self.specifier propertyForKey:@"key"];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
	self.selectedColor = (settings && settings[key]) ? settings[key] : @"default";
	
	if ([self.selectedColor isEqual:@"default"]) {
		// translate "default" into a color
		self.selectedColor = [DarkMessagesTheme defaultBalloonColorInHexForKey:key];
	}
		
	// make thumb image
	UIColor *color = [UIColor colorFromHexString:self.selectedColor];
	self.thumbnailView.image  = [color thumbnailWithSize:self.thumbnailView.frame.size];
}
@end

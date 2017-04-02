//
//  Settings for DarkMessages
//
//  ©2017 Sticktron
//

#import "../DarkMessages.h"
#import "../UIColor-Additions.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import <spawn.h>


#define VERSION_STRING	@"v1.2.0"

#define BLUE		[UIColor colorWithRed:15/255.0 green:132/255.0 blue:252/255.0 alpha:1] //#0F84FC
#define WHITE		[UIColor colorWithWhite:1 alpha:1]
#define BLACK		[UIColor colorWithWhite:0 alpha:1]
#define GRAY_9	 	[UIColor colorWithWhite:0.09 alpha:1.0] // #171717
#define GRAY_11 	[UIColor colorWithRed:0.11 green:0.11 blue:0.114 alpha:1.0] // #1c1c1d
#define GRAY_20		[UIColor colorWithRed:0.196 green:0.196 blue:0.200 alpha:1.0] // #323233
#define GRAY_40		[UIColor colorWithRed:0.39 green:0.39 blue:0.40 alpha:1.0] // 50% of systemGrayColor
#define GRAY_50		[UIColor colorWithRed:0.49 green:0.49 blue:0.50 alpha:1.0] // #7d7d80
#define GRAY_56		[UIColor colorWithRed:0.56 green:0.56 blue:0.58 alpha:1.0] // systemGrayColor (#8f8f94?)
#define GRAY_78		[UIColor colorWithRed:0.78 green:0.78 blue:0.80 alpha:1.0] // systemMidGrayColor

// Theme
static UIColor *tintColor = GRAY_9;
static UIColor *bgColor = GRAY_9;
static UIColor *separatorColor = GRAY_20;
static UIColor *cellBgColor = GRAY_11;
static UIColor *cellTextColor = WHITE;
static UIColor *footerTextColor = GRAY_56;
static UIColor *switchFillColor = BLUE;
static UIColor *switchKnobColor = BLACK;
static UIColor *switchBorderColor = BLUE;
static UIColor *chevronColor = BLUE;

static float headerHeight = 140.0f;
// static float cellHeight = 50.0f;

static PSListController *controller;


static void handleSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[controller reloadSpecifierID:@"Enabled" animated:YES];
}

static void themeStuff(NSArray *classes) {
	// NSArray *classes = @[ NSClassFromString(@"DarkMessagesSettings"), NSClassFromString(@"DarkMessagesColorPicker") ];
	
	// BG
	[[UITableView appearanceWhenContainedInInstancesOfClasses:classes] setBackgroundColor:bgColor];
	
	// Separators
	[[UITableView appearanceWhenContainedInInstancesOfClasses:classes] setSeparatorColor:separatorColor];
	
	// Cell BG
	[[NSClassFromString(@"PSTableCell") appearanceWhenContainedInInstancesOfClasses:classes] setBackgroundColor:cellBgColor];
	
	// Cell Disclosure Image
	[[NSClassFromString(@"PSTableCell") appearanceWhenContainedInInstancesOfClasses:classes] setTintColor:chevronColor];
	
	// Cell Label
	// ?? (tinted in PSTableCell subclass for now)
	
	// Section Text
	[[UILabel appearanceWhenContainedInInstancesOfClasses:classes] setTextColor:footerTextColor];
	
	// Switch
	[[UISwitch appearanceWhenContainedInInstancesOfClasses:classes] setOnTintColor:switchFillColor];
	[[UISwitch appearanceWhenContainedInInstancesOfClasses:classes] setThumbTintColor:switchKnobColor];
	[[UISwitch appearanceWhenContainedInInstancesOfClasses:classes] setTintColor:switchBorderColor];
}

static NSString * defaultColorForKey(NSString *key) {
	NSString *color = @"#000000";
	if ([key isEqualToString:@"BlueBalloonColor"]) {
		color = @"#0f84fc";
	} else if ([key isEqualToString:@"GreenBalloonColor"]) {
		color = @"#00d248";
	} else if ([key isEqualToString:@"GrayBalloonColor"]) {
		color = @"#333333";
	}
	return color;
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


@interface DarkMessagesSettingsController : PSListController
@property (nonatomic, strong) UIView *headerView;
@end

@implementation DarkMessagesSettingsController
- (instancetype)init {
	if (self = [super init]) {
		themeStuff(@[self.class]);
		
		// listen for changes from helper (to update the Dark Mode switch)
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
	self.navigationController.navigationController.navigationBar.tintColor = tintColor;
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
		headerView.backgroundColor = bgColor;
		headerView.opaque = YES;
		
		CGRect frame = CGRectMake(15, 47, headerView.bounds.size.width, 50);
		UILabel *tweakTitle = [[UILabel alloc] initWithFrame:frame];
		tweakTitle.text = @"DarkMessages";
		tweakTitle.font = [UIFont systemFontOfSize:40 weight:UIFontWeightThin];
		tweakTitle.textColor = WHITE;
		tweakTitle.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:tweakTitle];
		
		CGRect subtitleFrame = CGRectMake(15, 94, headerView.bounds.size.width, 20);
		UILabel *tweakSubtitle = [[UILabel alloc] initWithFrame:subtitleFrame];
		tweakSubtitle.text = VERSION_STRING;
		tweakSubtitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightThin];
		tweakSubtitle.textColor = footerTextColor;
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
// - (CGFloat)tableView:(id)tableView heightForRowAtIndexPath:(NSIndexPath *)path {
// 	return cellHeight;
// }

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
	// disable NightShift control
	if ([value boolValue]) {
		PSSpecifier *spec = [self specifierForID:@"NightShiftControl"];
		[self setPreferenceValue:@NO specifier:spec];
		[self reloadSpecifier:spec animated:YES];
	}
	// save value
	[self setPreferenceValue:value specifier:specifier];
}
- (void)setNightShiftControlValue:(id)value specifier:(id)specifier {
	// disable Noctis control
	if ([value boolValue]) {
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


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


// Custom Switch Cell ----------------------------------------------------------

@interface DMSwitchCell : PSSwitchTableCell
@end

@implementation DMSwitchCell
- (id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	if (self) {
		[self.textLabel setTextColor:cellTextColor];
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
		[self.textLabel setTextColor:cellTextColor];
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
		self.selectedColor = defaultColorForKey(key);
	}
	
	// make thumb image
	UIColor *color = [UIColor colorFromHexString:self.selectedColor];
	self.thumbnailView.image  = [color thumbnailWithSize:self.thumbnailView.frame.size];
}
@end


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


// DarkMessagesColorPicker -----------------------------------------------------

@interface DarkMessagesColorPicker : PSViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSArray *palettes;
@property (nonatomic, strong) NSString *selectedColor;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@end

static NSString * const kNameKey = @"name";
static NSString * const kHexKey = @"hex";

@implementation DarkMessagesColorPicker
- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = [self.specifier name];
	self.key = [self.specifier propertyForKey:@"key"];
	
	themeStuff(@[self.class]);
	
	UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;
	// tableView.rowHeight = cellHeight;
	[self.view addSubview:tableView];
	
	self.selectedIndexPath = nil;
	self.selectedColor = [self readPreferenceValue:self.specifier];
}

/* Tint navbar items. */
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// tint navbar
	self.navigationController.navigationController.navigationBar.tintColor = tintColor;
}
- (void)viewWillDisappear:(BOOL)animated {
	// un-tint navbar
	self.navigationController.navigationController.navigationBar.tintColor = nil;
	
	[super viewWillDisappear:animated];
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

- (NSArray *)palettes {
	if (!_palettes) {
		_palettes = @[
			@{
				@"title": 	@"",
				@"colors": 	@[ @{ kNameKey: @"Default", kHexKey: @"default" } ]
			},
			@{
				@"title": 	@"iOS Palette",
				@"colors": 	[self iOSColors]
			},
			@{
				@"title": 	@"Crayons",
				@"colors": 	[self crayonColors]
			}
		];
	}
	return _palettes;
}
- (NSArray *)sortPaletteByHue:(NSArray *)palette {
	NSArray *sortedPalette = [palette sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *color1, NSDictionary *color2) {
	
		CGFloat hue, saturation, brightness, alpha;
		[[UIColor colorFromHexString:color1[kHexKey]] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
		
		CGFloat hue2, saturation2, brightness2, alpha2;
		[[UIColor colorFromHexString:color2[kHexKey]] getHue:&hue2 saturation:&saturation2 brightness:&brightness2 alpha:&alpha2];
		
		if (hue < hue2) {
			return NSOrderedAscending;
		} else if (hue > hue2) {
			return NSOrderedDescending;
		}
		
		if (saturation < saturation2) {
			return NSOrderedAscending;
		} else if (saturation > saturation2) {
			return NSOrderedDescending;
		}
		
		if (brightness < brightness2) {
			return NSOrderedAscending;
		} else if (brightness > brightness2) {
			return NSOrderedDescending;
		}
		
		return NSOrderedSame;
	}];
	
	return sortedPalette;
}

/* TableView Stuff */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.palettes.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.palettes[section][@"title"];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.palettes[section][@"colors"] count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *MyCellIdentifier = @"ColorSwatchCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyCellIdentifier];
	
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MyCellIdentifier];
		cell.backgroundColor = cellBgColor;
		cell.opaque = YES;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.textLabel.textColor = cellTextColor;
		
		cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
		cell.detailTextLabel.textColor = footerTextColor;
		
		cell.imageView.layer.borderColor = [separatorColor CGColor];
		cell.imageView.layer.borderWidth = 0.5;
	}
	
	// prepare for reuse
	cell.textLabel.text = nil;
	cell.detailTextLabel.text = nil;
	cell.imageView.image = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	// get data for cell
	NSDictionary *colorDict = self.palettes[indexPath.section][@"colors"][indexPath.row];
	NSString *hexValue = colorDict[kHexKey];
	NSString *colorName = colorDict[kNameKey];
	NSString *swatchColor;
		
	// set title
	cell.textLabel.text = colorName;
	
	// set subtitle, swatch
	if (indexPath.section == 0) {
		// translate "default" into a color
		swatchColor = defaultColorForKey(self.key);
	} else {
		cell.detailTextLabel.text = hexValue;
		swatchColor = hexValue;
	}
	cell.imageView.image = [[UIColor colorFromHexString:swatchColor] thumbnailWithSize:CGSizeMake(48, 24)];
	
	// if we don't have a selected cell yet check if this cell should be selected
	if (!self.selectedIndexPath) {
		if ([hexValue isEqualToString:self.selectedColor]) {
			self.selectedIndexPath = indexPath;
		}
	}
	
	// check row if selected
	if ([indexPath isEqual:self.selectedIndexPath]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}

	return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
		// cell is already selected, do nothing
		return;
	}
	
	// un-check previously checked cell
	UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:self.selectedIndexPath];
	oldCell.accessoryType = UITableViewCellAccessoryNone;
	
	// check this cell
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	self.selectedIndexPath = indexPath;
	
	// save the value
	NSDictionary *colorDict = self.palettes[indexPath.section][@"colors"][indexPath.row];
	self.selectedColor = colorDict[kHexKey];
	[self setPreferenceValue:self.selectedColor specifier:self.specifier];
}

/* Color Palettes */
- (NSArray *)iOSColors {
	// This is the new palette introduced in iOS 7.
	
	return @[
  		@{ kNameKey: @"Purple", 		kHexKey: @"#5856D6" },
		@{ kNameKey: @"System Blue", 	kHexKey: @"#007AFF" },
		@{ kNameKey: @"Marine Blue", 	kHexKey: @"#34AADC" },
		@{ kNameKey: @"Light Blue", 	kHexKey: @"#5AC8FA" },
		@{ kNameKey: @"Pink", 			kHexKey: @"#FF2D55" },
		@{ kNameKey: @"System Red", 	kHexKey: @"#FF3B30" },
		@{ kNameKey: @"Orange", 		kHexKey: @"#FF9500" },
		@{ kNameKey: @"Yellow", 		kHexKey: @"#FFCC00" },
		@{ kNameKey: @"System Green", 	kHexKey: @"#4CD964" },
		@{ kNameKey: @"Gray", 			kHexKey: @"#8E8E93" }
	];
}
- (NSArray *)crayonColors {
	// These are the crayons from the OS X color picker.
	
	return @[
		@{ kNameKey: @"Snow",			kHexKey: @"#FFFFFF" }, //White
		@{ kNameKey: @"Mercury",		kHexKey: @"#E6E6E6" },
		@{ kNameKey: @"Silver", 		kHexKey: @"#CCCCCC" },
		@{ kNameKey: @"Magnesium", 		kHexKey: @"#B3B3B3" },
		@{ kNameKey: @"Aluminum", 		kHexKey: @"#999999" },
		@{ kNameKey: @"Nickel", 		kHexKey: @"#808080" },
		@{ kNameKey: @"Tin", 			kHexKey: @"#7F7F7F" },
		@{ kNameKey: @"Steel", 			kHexKey: @"#666666" },
		@{ kNameKey: @"Iron", 			kHexKey: @"#4C4C4C" },
		@{ kNameKey: @"Tungsten", 		kHexKey: @"#333333" },
		@{ kNameKey: @"Lead", 			kHexKey: @"#191919" },
		@{ kNameKey: @"Licorice", 		kHexKey: @"#000000" }, //Black
				
		@{ kNameKey: @"Marascino", 		kHexKey: @"#FF0000" }, //Red
		@{ kNameKey: @"Cayenne", 		kHexKey: @"#800000" },
		@{ kNameKey: @"Salmon", 		kHexKey: @"#FF6666" },
		@{ kNameKey: @"Maroon", 		kHexKey: @"#800040" },
		@{ kNameKey: @"Strawberry", 	kHexKey: @"#FF0080" },
		@{ kNameKey: @"Carnation", 		kHexKey: @"#FF6FCF" },
		@{ kNameKey: @"Magenta", 		kHexKey: @"#FF00FF" }, //Magenta
  		@{ kNameKey: @"Plum", 			kHexKey: @"#800080" },
		@{ kNameKey: @"BubbleGum", 		kHexKey: @"#FF66FF" },
  		@{ kNameKey: @"Lavender", 		kHexKey: @"#CC66FF" },
		@{ kNameKey: @"Grape", 			kHexKey: @"#8000FF" },
		@{ kNameKey: @"Eggplant", 		kHexKey: @"#400080" },
		@{ kNameKey: @"Blueberry", 		kHexKey: @"#0000FF" }, //Blue
		@{ kNameKey: @"Midnight", 		kHexKey: @"#000080" },
		@{ kNameKey: @"Orchid",			kHexKey: @"#6666FF" },
		@{ kNameKey: @"Ocean", 			kHexKey: @"#004080" },
		@{ kNameKey: @"Aqua", 			kHexKey: @"#0080FF" },
		@{ kNameKey: @"Sky", 			kHexKey: @"#66CCFF" },
		@{ kNameKey: @"Turquoise", 		kHexKey: @"#00FFFF" }, //Cyan
		@{ kNameKey: @"Teal", 			kHexKey: @"#008080" },
		@{ kNameKey: @"Ice", 			kHexKey: @"#66FFFF" },
		@{ kNameKey: @"Spindrift", 		kHexKey: @"#66FFCC" },
		@{ kNameKey: @"Sea Foam", 		kHexKey: @"#00FF80" },
		@{ kNameKey: @"Moss", 			kHexKey: @"#008040" },
		@{ kNameKey: @"Spring", 		kHexKey: @"#00FF00" }, //Green
		@{ kNameKey: @"Clover", 		kHexKey: @"#008000" },
		@{ kNameKey: @"Flora", 			kHexKey: @"#66FF66" },
		@{ kNameKey: @"Fern", 			kHexKey: @"#408000" },
		@{ kNameKey: @"Lime", 			kHexKey: @"#80FF00" },
		@{ kNameKey: @"Honeydew", 		kHexKey: @"#CCFF66" },
		@{ kNameKey: @"Lemon", 			kHexKey: @"#FFFF00" }, //Yellow
		@{ kNameKey: @"Asperagus", 		kHexKey: @"#808000" },
		@{ kNameKey: @"Banana", 		kHexKey: @"#FFFF66" },
		@{ kNameKey: @"Cantaloupe", 	kHexKey: @"#FFCC66" },
		@{ kNameKey: @"Tangerine", 		kHexKey: @"#FF8000" },
		@{ kNameKey: @"Mocha", 			kHexKey: @"#804000" },
	];
}
@end

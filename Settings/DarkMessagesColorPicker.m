//
//  DarkMessagesColorPicker.m
//  ColorPicker for DarkMessages
//
//  ©2017 Sticktron
//

#import "DarkMessagesColorPicker.h"

#import <Preferences/PSSpecifier.h>
#import "../DarkMessages.h"
#import "../UIColor-Additions.h"
#import "DarkMessagesTheme.h"


static NSString * const kNameKey = @"name";
static NSString * const kHexKey = @"hex";


@implementation DarkMessagesColorPicker

- (NSArray *)palettes {
	if (!_palettes) {
		_palettes = @[
			@{
				@"title": 	@"",
				@"colors": 	@[ @{ kNameKey: @"Default", kHexKey: @"default" } ]
			},
			@{
				@"title": 	@"System Palette",
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

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = [self.specifier name];
	self.key = [self.specifier propertyForKey:@"key"];
	
	[DarkMessagesTheme themeStuffInClasses:@[ self.class ]];
	
	UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;
	[self.view addSubview:tableView];
	
	self.selectedIndexPath = nil;
	self.selectedColor = [self readPreferenceValue:self.specifier];
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
		cell.backgroundColor = [DarkMessagesTheme cellBgColor];
		cell.opaque = YES;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.textLabel.textColor = [DarkMessagesTheme cellTextColor];
		
		cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
		cell.detailTextLabel.textColor = [DarkMessagesTheme footerTextColor];
		
		cell.imageView.layer.borderColor = [DarkMessagesTheme separatorColor].CGColor;
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
		swatchColor = [DarkMessagesTheme defaultBalloonColorInHexForKey:self.key];
	} else {
		cell.detailTextLabel.text = hexValue;
		swatchColor = hexValue;
	}
	cell.imageView.image = [[UIColor colorFromHexString:swatchColor] thumbnailWithSize:CGSizeMake(48, 24)];
		
///// DEBUG
	// UILabel *testLabel = [[UILabel alloc] initWithFrame:cell.imageView.bounds];
	// testLabel.text = @"ABC";
	// testLabel.textAlignment = NSTextAlignmentCenter;
	// testLabel.font = [UIFont systemFontOfSize:12];
	// if ([[UIColor colorFromHexString:swatchColor] isLightColor]) {
	// 	testLabel.textColor = UIColor.blackColor;
	// } else {
	// 	testLabel.textColor = UIColor.whiteColor;
	// }
	// [cell.imageView addSubview:testLabel];
//////////
	
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

@end

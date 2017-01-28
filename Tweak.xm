/*
 * Dark theme for Messages app.
 * iOS 10
 * @sticktron
 */

@interface CKUITheme : NSObject
@end

@interface CKUIThemeDark : CKUITheme
@end

@interface CKUIBehavior : NSObject
@property (nonatomic, readonly) CKUITheme *theme;
- (id)theme;
@end

@interface CKUIBehaviorPhone : CKUIBehavior
@end

@interface CKUIBehaviorPad : CKUIBehavior
@end

@interface CKAvatarNavigationBar : UINavigationBar
@end

@interface CKAvatarContactNameCollectionReusableView : UICollectionReusableView
- (int)style;
- (void)setStyle:(int)style;
@end

@interface CKNavigationBarCanvasView : UIView
- (id)titleView;
@end

@interface CKComposeNavbarManagerContentView
- (id)canvasView;
@end

@interface CKDetailsCell : UITableViewCell
@end


@protocol CKDetailsCell <NSObject>
@required
+ (NSString *)reuseIdentifier;
+ (BOOL)shouldHighlight;
@end

@interface CKDetailsGroupNameCell : CKDetailsCell <CKDetailsCell>
-(UILabel*)textLabel;
@end


static CKUIThemeDark *darkTheme;


%group Phone
%hook CKUIBehaviorPhone
- (id)theme {
	if (!darkTheme) {
		darkTheme = [[%c(CKUIThemeDark) alloc] init];
	}
	return darkTheme;
}
%end
%end


%group Pad
%hook CKUIBehaviorPad
- (id)theme {
	if (!darkTheme) {
		darkTheme = [[%c(CKUIThemeDark) alloc] init];
	}
	return darkTheme;
}
%end
%end


%group Common
%hook CKAvatarNavigationBar
- (void)_setBarStyle:(int)style {
	%orig(1);
}
- (int)barStyle {
	return 1;
}
%end

%hook CKAvatarContactNameCollectionReusableView
- (void)setStyle:(int)style {
	%orig(3);
}
- (int)style {
	return 3;
}
%end

%hook CKComposeNavbarManagerContentView
- (void)layoutSubviews {
	%orig;
	
	CKNavigationBarCanvasView *cv = [self canvasView];
	UILabel *tv = (UILabel *)[cv titleView];
	tv.textColor = UIColor.whiteColor;
}
%end

%hook CKDetailsGroupNameCell
-(UILabel*)textLabel {
	UILabel* tl = %orig;
	tl.textColor = [UIColor whiteColor];
	return tl;
}
%end

%hook CKDetailsContactsTableViewCell
- (UILabel*)nameLabel {
	UILabel* nl = %orig;
	nl.textColor = [UIColor whiteColor];
	return nl;
}
%end

%end


%ctor {
	@autoreleasepool {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			%init(Pad);
		} else {
			%init(Phone);
		}
		
		%init(Common);
	}
}

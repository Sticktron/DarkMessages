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


static CKUIThemeDark *darkTheme;

%hook CKUIBehaviorPhone
- (id)theme {
	if (!darkTheme) {
		darkTheme = [[%c(CKUIThemeDark) alloc] init];
	}
	return darkTheme;
}
%end

%hook CKUIBehaviorPad
- (id)theme {
	if (!darkTheme) {
		darkTheme = [[%c(CKUIThemeDark) alloc] init];
	}
	return darkTheme;
}
%end

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

%hook CKNavigationBarCanvasView
- (id)titleView {
	UILabel *tv = %orig;
	tv.textColor = UIColor.whiteColor;
	return tv;
}
%end

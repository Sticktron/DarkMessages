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

@interface CKAvatarNavigationBar : UINavigationBar
@end

@interface CKAvatarContactNameCollectionReusableView : UICollectionReusableView
- (int)style;
- (void)setStyle:(int)style;
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


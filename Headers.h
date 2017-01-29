//
// Private APIs
//

@interface CKUITheme : NSObject
@end

@interface CKUIThemeDark : CKUITheme
@end

@interface CKUIBehavior : NSObject
- (id)theme;
@end

@interface CKUIBehaviorPhone : CKUIBehavior
@end

@interface CKUIBehaviorPad : CKUIBehavior
@end

@interface CKAvatarNavigationBar : UINavigationBar
- (void)_setBarStyle:(int)style;
@end

@interface CKAvatarContactNameCollectionReusableView : UICollectionReusableView
- (void)setStyle:(int)style;
@end

@interface CKAvatarTitleCollectionReusableView : UICollectionReusableView
- (void)setStyle:(int)arg1;
@end

@interface CKNavigationBarCanvasView : UIView
- (void)setTitleView:(id)titleView;
@end

@interface CKDetailsContactsTableViewCell : UITableViewCell
- (UILabel *)nameLabel;
@end

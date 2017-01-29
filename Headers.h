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

@interface CKComposeNavbarManagerContentView : UIView
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

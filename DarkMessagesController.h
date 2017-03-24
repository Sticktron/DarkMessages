//
//  DarkMessagesController.h
//  DarkMessages
//
//  ©2017 Sticktron
//

@class NCNotificationViewController;

@interface DarkMessagesController : NSObject
@property (nonatomic, readonly) BOOL isDark;
@property (nonatomic) BOOL nightShiftControlEnabled;
@property (nonatomic) BOOL noctisControlEnabled;
@property (nonatomic, strong) NCNotificationViewController *qrViewController;
- (void)setDarkMode:(BOOL)enabled;
- (void)loadSettings;
- (void)syncStateWithTriggers;
- (void)killMobileSMS;
@end

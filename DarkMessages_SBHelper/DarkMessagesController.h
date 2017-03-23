//
//  DarkMessagesController.h
//  DarkMessages
//
//  ©2017 Sticktron
//

#import "../DarkMessages.h"

@interface DarkMessagesController : NSObject
@property (nonatomic, readonly) BOOL isDark;
@property (nonatomic) BOOL nightShiftControlEnabled;
@property (nonatomic) BOOL noctisControlEnabled;
@property (nonatomic, strong) NCNotificationViewController *qrViewController;
- (void)loadSettings;
- (void)syncStateWithTriggers;
- (void)killMobileSMS;
@end

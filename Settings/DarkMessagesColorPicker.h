//
//  DarkMessagesColorPicker.h
//  ColorPicker for DarkMessages
//
//  ©2017 Sticktron
//

#import <Preferences/PSViewController.h>

@interface DarkMessagesColorPicker : PSViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSArray *palettes;
@property (nonatomic, strong) NSString *selectedColor;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@end

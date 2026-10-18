// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// In-app settings panel.
///
/// Presented over Snapchat's own navigation controller so it inherits the app's
/// chrome. Every row writes straight through to NSUserDefaults and the hooks read
/// those values on their next call, so a toggle takes effect without a respring.
@interface SXSettingsViewController : UITableViewController

/// Presents the panel over `presenter`. Safe to call repeatedly; a second call is
/// ignored while the panel is already up.
+ (void)presentFrom:(UIViewController *)presenter;

/// The frontmost view controller in the key window, or nil when no window is ready.
/// Feature code uses this instead of assuming a visible controller exists.
+ (nullable UIViewController *)topViewController;

@end

NS_ASSUME_NONNULL_END
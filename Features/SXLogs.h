// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Log capture and the log viewer.
///
/// The original keeps a file (`KMManageroptions._logFile`, `_logFileExists`) surfaced
/// through `KMUtilLogsVC` with `Copy Logs` / `Clear Logs`. This rebuild captures the
/// same lines in memory plus an on-disk file, and adds hook gaps — the feature list a
/// Snapchat update has broken — because that is the first thing a user needs to know.
@interface SXLogs : NSObject

/// Appends one line. Called by `SXLog`/`SXDebugLog` through `SXLogs`.
+ (void)record:(NSString *)line;

/// Everything captured this session, oldest first.
+ (NSString *)collectedText;

/// A short "N lines" label for the settings row.
+ (NSString *)lineCountLabel;

/// Presents the log from `presenter`, with copy and clear actions.
+ (void)presentFrom:(UIViewController *)presenter;

@end

NS_ASSUME_NONNULL_END
// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Privacy controls.
///
/// Each hook here suppresses a *local* mutation rather than only the network call.
/// That distinction is the whole design: read receipts are raised by
/// `-_markMessagesAsReadForConversationId:chatPageSource:conversationViewModel:` on
/// `SCArroyoMessageActionHandler`, and that same call performs the upload. Blocking
/// only the upload would leave the sender's UI showing a read that never registered.
///
/// Every selector below is observed in the shipped binary. None of the method bodies
/// are confirmed, so each hook is installed defensively and records a gap when a
/// selector disappears.
@interface SXPrivacy : NSObject

+ (void)install;

@end

NS_ASSUME_NONNULL_END
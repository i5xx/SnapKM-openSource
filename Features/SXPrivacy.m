// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import "SXPrivacy.h"
#import "../Shadow/SXHook.h"
#import "../Shadow/SXLog.h"
#import "../Shadow/SXSettings.h"

/// Longer than the 10s default for chat classes, which Snapchat loads late.
static const NSTimeInterval kSXChatHookTimeout = 20.0;

@implementation SXPrivacy

+ (void)install {
  // Read receipts.
  [SXHook installWhenAvailable:@"SCArroyoMessageActionHandler"
                     owner:[SXPrivacy class]
                     original:@selector(_markMessagesAsReadForConversationId:
                                             chatPageSource:conversationViewModel:)
                   replacement:@selector(sx_markMessagesAsReadForConversationId:
                                             chatPageSource:conversationViewModel:)
                       timeout:kSXChatHookTimeout];

  // Message deletion: keep the local copy instead of letting Snapchat purge it.
  [SXHook installWhenAvailable:@"SCArroyoMessageActionHandler"
                     owner:[SXPrivacy class]
                     original:@selector(_markSnapAsInvalidForConversationId:messageId:)
                   replacement:@selector(sx_markSnapAsInvalidForConversationId:messageId:)
                       timeout:kSXChatHookTimeout];

  // Typing indicator. SCChatTypingHandler is the only path that raises typing state,
  // so suppressing it covers every conversation at once.
  [SXHook installWhenAvailable:@"SCChatTypingHandler"
                     owner:[SXPrivacy class]
                     original:@selector(_updateTalkSessionWithTypingState:
                                                   typingActivityType:)
                   replacement:@selector(sx_updateTalkSessionWithTypingState:
                                                   typingActivityType:)
                       timeout:kSXChatHookTimeout];

  // Screenshot / screen-record alerts on the story surface.
  [SXHook installWhenAvailable:@"SCBaseMediaOperaPresenter"
                     owner:[SXPrivacy class]
                     original:@selector(_reportStorySnapScreenshotWithStorySnap:
                                                   hasDepthContent:)
                   replacement:@selector(sx_reportStorySnapScreenshotWithStorySnap:
                                                   hasDepthContent:)
                       timeout:kSXChatHookTimeout];

  // The same two events, as surfaced by the chat surface.
  [SXHook installWhenAvailable:@"SCChatViewControllerV3"
                     owner:[SXPrivacy class]
                     original:@selector(conversationId:userDidTakeScreenshotForSnap:)
                   replacement:@selector(sx_conversationId:userDidTakeScreenshotForSnap:)
                       timeout:kSXChatHookTimeout];

  [SXHook installWhenAvailable:@"SCChatViewControllerV3"
                     owner:[SXPrivacy class]
                     original:@selector(conversationId:userDidScreenRecordForSnap:)
                   replacement:@selector(sx_conversationId:userDidScreenRecordForSnap:)
                       timeout:kSXChatHookTimeout];
}

#pragma mark - Hooks

- (void)sx_markMessagesAsReadForConversationId:(NSString *)conversationId
                                  chatPageSource:(id)chatPageSource
                          conversationViewModel:(id)viewModel {
  if ([SXSettings shared].disableReadReceipts) {
    SXDebugLog("read receipt suppressed: %@", conversationId);
    return;
  }
  [self sx_markMessagesAsReadForConversationId:conversationId
                                 chatPageSource:chatPageSource
                         conversationViewModel:viewModel];
}

- (void)sx_markSnapAsInvalidForConversationId:(NSString *)conversationId
                                    messageId:(NSString *)messageId {
  if ([SXSettings shared].disableMessageDeletion) {
    SXDebugLog("deletion suppressed: %@/%@", conversationId, messageId);
    return;
  }
  [self sx_markSnapAsInvalidForConversationId:conversationId messageId:messageId];
}

- (void)sx_updateTalkSessionWithTypingState:(id)state typingActivityType:(NSInteger)type {
  if ([SXSettings shared].disableTypingIndicator)
    return;
  [self sx_updateTalkSessionWithTypingState:state typingActivityType:type];
}

- (void)sx_reportStorySnapScreenshotWithStorySnap:(id)storySnap
                                  hasDepthContent:(BOOL)hasDepth {
  if ([SXSettings shared].disableScreenshotAlert)
    return;
  [self sx_reportStorySnapScreenshotWithStorySnap:storySnap hasDepthContent:hasDepth];
}

- (void)sx_conversationId:(NSString *)conversationId
    userDidTakeScreenshotForSnap:(id)snap {
  if ([SXSettings shared].disableScreenshotAlert) {
    SXDebugLog("screenshot alert suppressed: %@", conversationId);
    return;
  }
  [self sx_conversationId:conversationId userDidTakeScreenshotForSnap:snap];
}

- (void)sx_conversationId:(NSString *)conversationId
    userDidScreenRecordForSnap:(id)snap {
  if ([SXSettings shared].disableScreenshotAlert) {
    SXDebugLog("screen-record alert suppressed: %@", conversationId);
    return;
  }
  [self sx_conversationId:conversationId userDidScreenRecordForSnap:snap];
}

@end
// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import "SXLogs.h"
#import "../Shadow/SXHook.h"
#import "../Shadow/SXLog.h"

/// Bounded so a long session cannot exhaust memory. The file keeps the tail, so a
/// user reading the log after the fact still sees what matters.
static const NSUInteger kSXLogLineLimit = 500;

static NSMutableArray<NSString *> *SXLogLines(void) {
  static NSMutableArray<NSString *> *lines;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    lines = [NSMutableArray array];
  });
  return lines;
}

@implementation SXLogs

+ (NSURL *)logFileURL {
  NSURL *docs = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                       inDomains:NSUserDomainMask]
                    .firstObject;
  return [[docs URLByAppendingPathComponent:@"snapkm"] URLByAppendingPathComponent:@"snapkm.log"];
}

+ (void)record:(NSString *)line {
  if (line.length == 0)
    return;

  dispatch_async(dispatch_get_main_queue(), ^{
    NSMutableArray<NSString *> *lines = SXLogLines();
    [lines addObject:line];
    if (lines.count > kSXLogLineLimit)
      [lines removeObjectsInRange:NSMakeRange(0, lines.count - kSXLogLineLimit)];

    // Written on every line rather than batched: a crash must not lose the lines
    // that explain it.
    NSURL *url = [self logFileURL];
    [NSFileManager.defaultManager createDirectoryAtURL:url.URLByDeletingLastPathComponent
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:url.path];
    if (handle == nil)
      [[NSFileManager defaultManager] createFileAtPath:url.path contents:nil attributes:nil];
    handle = [NSFileHandle fileHandleForWritingAtPath:url.path];
    [handle seekToEndOfFile];
    [handle writeData:[[line stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
  });
}

+ (NSString *)collectedText {
  __block NSString *text;
  dispatch_sync(dispatch_get_main_queue(), ^{
    text = [SXLogLines() componentsJoinedByString:@"\n"];
  });
  if (text.length == 0)
    text = @"No log output yet.";
  return text;
}

+ (NSString *)lineCountLabel {
  __block NSUInteger count;
  dispatch_sync(dispatch_get_main_queue(), ^{
    count = SXLogLines().count;
  });
  return [NSString stringWithFormat:@"%lu lines", (unsigned long)count];
}

+ (void)presentFrom:(UIViewController *)presenter {
  UIViewController *host = presenter ?: [self frontViewController];
  if (host == nil)
    return;

  NSString *body = [NSString stringWithFormat:@"%@\n\n-- hook gaps --\n%@",
                                              [self collectedText],
                                              [SXHook recordedGaps].count > 0
                                                  ? [[SXHook recordedGaps]
                                                        componentsJoinedByString:@"\n"]
                                                  : @"none"];

  UIViewController *viewer = [[UIViewController alloc] init];
  viewer.title = @"SnapKM Logs";
  viewer.view.backgroundColor = UIColor.systemBackgroundColor;

  UITextView *text = [[UITextView alloc] init];
  text.translatesAutoresizingMaskIntoConstraints = NO;
  text.editable = NO;
  text.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
  text.text = body;
  text.accessibilityIdentifier = @"sx.log.text";

  UIBarButtonItem *copy = [[UIBarButtonItem alloc] initWithTitle:@"Copy"
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(copyLog)];
  copy.accessibilityIdentifier = @"sx.log.copy";

  UIBarButtonItem *clear = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(clearLog)];
  clear.accessibilityIdentifier = @"sx.log.clear";

  viewer.navigationItem.rightBarButtonItems = @[ clear, copy ];
  [viewer.view addSubview:text];
  [NSLayoutConstraint activateConstraints:@[
    [text.topAnchor constraintEqualToAnchor:viewer.view.safeAreaLayoutGuide.topAnchor],
    [text.bottomAnchor constraintEqualToAnchor:viewer.view.bottomAnchor],
    [text.leadingAnchor constraintEqualToAnchor:viewer.view.leadingAnchor constant:8],
    [text.trailingAnchor constraintEqualToAnchor:viewer.view.trailingAnchor constant:-8],
  ]];

  UINavigationController *nav =
      [[UINavigationController alloc] initWithRootViewController:viewer];
  nav.modalPresentationStyle = UIModalPresentationFullScreen;
  [host presentViewController:nav animated:YES completion:nil];
}

+ (nullable UIViewController *)frontViewController {
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if (![scene isKindOfClass:[UIWindowScene class]])
      continue;
    for (UIWindow *window in ((UIWindowScene *)scene).windows) {
      if (!window.isKeyWindow)
        continue;
      UIViewController *controller = window.rootViewController;
      while (controller.presentedViewController)
        controller = controller.presentedViewController;
      return controller;
    }
  }
  return nil;
}

+ (void)copyLog {
  UIPasteboard.generalPasteboard.string = [self collectedText];
  SXLog("logs copied");
}

+ (void)clearLog {
  dispatch_async(dispatch_get_main_queue(), ^{
    [SXLogLines() removeAllObjects];
    NSURL *url = [self logFileURL];
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];
    SXLog("logs cleared");
  });
}

@end
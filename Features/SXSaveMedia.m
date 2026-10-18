// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import "SXSaveMedia.h"
#import "../Shadow/SXHook.h"
#import "../Shadow/SXLog.h"
#import "../Shadow/SXSettings.h"
#import "../Shadow/SXSettingsViewController.h"

static NSString *const kSXCategoryAudio = @"Audio";
static NSString *const kSXCategoryVideo = @"Video";
static NSString *const kSXIndexName = @"snap.plist";

/// The only shape of the media accessor confirmed from the interface metadata.
///
/// UNKNOWN: whether `SCChatBaseSnapOperaDataSource`'s post object actually declares
/// this. Declared as a local protocol rather than a category so the build does not
/// claim knowledge it does not have; `respondsToSelector:` still gates the call.
@protocol SXSnapMediaPost <NSObject>
- (nullable NSData *)snapMediaData;
@end

@implementation SXSaveMedia

+ (void)install {
  [SXHook installWhenAvailable:@"SCChatBaseSnapOperaDataSource"
                     owner:[SXSaveMedia class]
                     original:@selector(savePhotoPost:)
                   replacement:@selector(sx_savePhotoPost:)
                       timeout:20.0];
  [SXHook installWhenAvailable:@"SCChatBaseSnapOperaDataSource"
                     owner:[SXSaveMedia class]
                     original:@selector(saveVideoPost:)
                   replacement:@selector(sx_saveVideoPost:)
                       timeout:20.0];
}

#pragma mark - Storage

+ (NSURL *)saveRootURL {
  NSURL *root = [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                        inDomains:NSUserDomainMask]
                     .firstObject URLByAppendingPathComponent:@"snap"];

  NSFileManager *fm = NSFileManager.defaultManager;
  for (NSString *category in @[ kSXCategoryAudio, kSXCategoryVideo ]) {
    NSURL *dir = [root URLByAppendingPathComponent:category isDirectory:YES];
    if (![fm fileExistsAtPath:dir.path])
      [fm createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
  }
  return root;
}

+ (NSURL *)indexURL {
  return [[self saveRootURL] URLByAppendingPathComponent:kSXIndexName];
}

+ (long long)fileSize:(NSURL *)url {
  NSNumber *size = nil;
  [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
  return size.longLongValue;
}

+ (NSMutableDictionary *)loadIndex {
  NSURL *url = [self indexURL];
  if (![NSFileManager.defaultManager fileExistsAtPath:url.path])
    return [NSMutableDictionary dictionary];

  NSDictionary *existing = [NSDictionary dictionaryWithContentsOfURL:url];
  return [existing isKindOfClass:[NSDictionary class]] ? [existing mutableCopy]
                                                     : [NSMutableDictionary dictionary];
}

+ (NSURL *)writeData:(NSData *)data
            category:(NSString *)category
          extension:(NSString *)extension {
  if (data.length == 0)
    return nil;

  NSURL *dir = [[self saveRootURL] URLByAppendingPathComponent:category isDirectory:YES];
  NSURL *target = [dir URLByAppendingPathComponent:
                              [NSString stringWithFormat:@"%@.%@", NSUUID.UUID.UUIDString,
                                                         extension]];

  NSError *error = nil;
  if (![data writeToURL:target options:NSDataWritingAtomic error:&error]) {
    SXLog("save failed: %@ (%@)", target.lastPathComponent, error.localizedDescription);
    return nil;
  }

  [self recordInIndex:target category:category];
  SXDebugLog("saved %@ (%lu bytes)", target.lastPathComponent, (unsigned long)data.length);
  return target;
}

/// Appends one entry so a saved-media browser can enumerate what exists.
+ (void)recordInIndex:(NSURL *)fileURL category:(NSString *)category {
  NSMutableDictionary *index = [self loadIndex];
  NSMutableArray *entries = index[category] ?: [NSMutableArray array];
  [entries addObject:@{
    @"file" : fileURL.lastPathComponent,
    @"date" : @((NSInteger)NSDate.date.timeIntervalSince1970),
    @"size" : @([self fileSize:fileURL]),
  }];
  index[category] = entries;
  [index writeToURL:[self indexURL] atomically:YES];
}

+ (nullable NSArray<NSDictionary<NSString *, id> *> *)entriesForCategory:(NSString *)category {
  NSArray *entries = [self loadIndex][category];
  return [entries isKindOfClass:[NSArray class]] ? entries : nil;
}

+ (void)confirmSavedFrom:(nullable UIView *)sourceView {
  UIViewController *presenter = [SXSettingsViewController topViewController];
  if (presenter == nil)
    return;

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Saved"
                                                               message:nil
                                                        preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleDefault
                                          handler:nil]];

  // An unanchored popover is undefined on iPad.
  UIPopoverPresentationController *popover = alert.popoverPresentationController;
  if (popover) {
    popover.sourceView = sourceView ?: presenter.view;
    popover.sourceRect = CGRectMake(CGRectGetMidX(popover.sourceView.bounds),
                                    CGRectGetMaxY(popover.sourceView.bounds), 1, 1);
  }

  [presenter presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Snapchat hooks

/// Appends a local copy to Snapchat's own save rather than replacing it.
- (void)sx_savePhotoPost:(id)post {
  if ([SXSettings shared].saveMedia) {
    NSData *bytes = [self sx_mediaDataForPost:post];
    if (bytes) {
      if ([SXSaveMedia writeData:bytes category:kSXCategoryVideo extension:@"jpg"])
        [SXSaveMedia confirmSavedFrom:nil];
    } else {
      // Degrades to Snapchat's behaviour instead of failing; logged so the gap is
      // visible in the log viewer.
      SXLog("save hook: no bytes on photo post (accessor unconfirmed)");
    }
  }
  [self sx_savePhotoPost:post];
}

- (void)sx_saveVideoPost:(id)post {
  if ([SXSettings shared].saveMedia) {
    NSData *bytes = [self sx_mediaDataForPost:post];
    if (bytes) {
      if ([SXSaveMedia writeData:bytes category:kSXCategoryVideo extension:@"mp4"])
        [SXSaveMedia confirmSavedFrom:nil];
    } else {
      SXLog("save hook: no bytes on video post (accessor unconfirmed)");
    }
  }
  [self sx_saveVideoPost:post];
}

/// Extracts raw bytes from a snap post.
///
/// UNKNOWN: the original resolves this through Snapchat's media pipeline, not a single
/// documented accessor. This recognises the two shapes that can be confirmed from the
/// interface alone and returns nil for everything else, so the hook degrades to
/// Snapchat's own save rather than saving garbage. Re-check
/// `SCChatBaseSnapOperaDataSource` once a decompiler is available.
- (nullable NSData *)sx_mediaDataForPost:(id)post {
  if ([post isKindOfClass:[NSData class]])
    return (NSData *)post;
  if ([post conformsToProtocol:@protocol(SXSnapMediaPost)] &&
      [post respondsToSelector:@selector(snapMediaData)])
    return [(id<SXSnapMediaPost>)post snapMediaData];
  return nil;
}

@end
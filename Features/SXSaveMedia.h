// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Media saving.
///
/// Storage layout reproduced from the shipped binary's literal path strings:
///
/// ```
/// <Documents>/snap.plist              index
/// <Documents>/snap.bundle             payload container
/// <Documents>/snap/Audio/<uuid>.{json,mp3,png}
/// <Documents>/snap/Video/<uuid>.{json,mp4,png}
/// ```
///
/// The original's `SavePhotoPost:` / `SaveVideoPost:` are appended to Snapchat's own
/// save rather than replacing it, so a user keeps the behaviour they already had.
@interface SXSaveMedia : NSObject

+ (void)install;

/// Root of the save directory, created on first use.
+ (NSURL *)saveRootURL;

/// Writes `data` under `category` (Audio or Video) and indexes it. Returns the file
/// URL, or nil when the write fails.
+ (nullable NSURL *)writeData:(NSData *)data
                    category:(NSString *)category
                  extension:(NSString *)extension;

/// Lists indexed entries for a category, newest first.
+ (nullable NSArray<NSDictionary<NSString *, id> *> *)entriesForCategory:(NSString *)category;

/// Shows the "saved" confirmation. One path for both the button and auto-save so the
/// feedback is identical.
+ (void)confirmSavedFrom:(nullable UIView *)sourceView;

@end

NS_ASSUME_NONNULL_END
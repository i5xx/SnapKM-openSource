// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Keys are the stable on-disk contract. Renaming one silently resets a user's
/// choice, so treat every string here as a compatibility surface.
extern NSString *const SXKeySaveMedia;
extern NSString *const SXKeySaveChats;
extern NSString *const SXKeyReplaceSaveButton;
extern NSString *const SXKeyInvisibleViewing;
extern NSString *const SXKeyDisableScreenshotAlert;
extern NSString *const SXKeyDisableReadReceipts;
extern NSString *const SXKeyDisableTypingIndicator;
extern NSString *const SXKeyDisableMessageDeletion;
extern NSString *const SXKeyDisableAds;
extern NSString *const SXKeySpoofLocation;
extern NSString *const SXKeySpoofLatitude;
extern NSString *const SXKeySpoofLongitude;
extern NSString *const SXKeyCloakAntiDetect;
extern NSString *const SXKeyDebugLogging;

/// Single source of truth for every toggle, backed by NSUserDefaults so values
/// survive relaunch without an explicit save step.
///
/// Every property reads through on access rather than caching. One plist lookup
/// per call is cheaper than the invalidation logic a cache would need, and it means
/// a toggle takes effect on the very next hook invocation with no respring.
@interface SXSettings : NSObject

@property (class, readonly, nonatomic) SXSettings *shared;

// Saving
@property (nonatomic, readonly) BOOL saveMedia;
@property (nonatomic, readonly) BOOL saveChats;
@property (nonatomic, readonly) BOOL replaceSaveButton;

// Privacy
@property (nonatomic, readonly) BOOL invisibleViewing;
@property (nonatomic, readonly) BOOL disableScreenshotAlert;
@property (nonatomic, readonly) BOOL disableReadReceipts;
@property (nonatomic, readonly) BOOL disableTypingIndicator;
@property (nonatomic, readonly) BOOL disableMessageDeletion;
@property (nonatomic, readonly) BOOL disableAds;

// Snap Map spoof. Ignored unless spoofLocation is on.
@property (nonatomic, readonly) BOOL spoofLocation;
@property (nonatomic, readonly) double spoofLatitude;
@property (nonatomic, readonly) double spoofLongitude;

// Diagnostics
@property (nonatomic, readonly) BOOL cloakAntiDetect;
@property (nonatomic, readonly) BOOL debugLogging;

/// Reads a boolean toggle, tolerating a missing or mistyped key.
- (BOOL)boolForKey:(NSString *)key default:(BOOL)defaultValue;
- (double)doubleForKey:(NSString *)key default:(double)defaultValue;

- (void)setBool:(BOOL)value forKey:(NSString *)key;

/// Called when the settings panel closes.
- (void)reload;

@end

NS_ASSUME_NONNULL_END
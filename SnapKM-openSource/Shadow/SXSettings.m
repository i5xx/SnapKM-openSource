// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import "SXSettings.h"
#import "SXLog.h"

NSString *const SXKeySaveMedia = @"sx_save_media";
NSString *const SXKeySaveChats = @"sx_save_chats";
NSString *const SXKeyReplaceSaveButton = @"sx_replace_save_button";
NSString *const SXKeyInvisibleViewing = @"sx_invisible_viewing";
NSString *const SXKeyDisableScreenshotAlert = @"sx_disable_screenshot_alert";
NSString *const SXKeyDisableReadReceipts = @"sx_disable_read_receipts";
NSString *const SXKeyDisableTypingIndicator = @"sx_disable_typing_indicator";
NSString *const SXKeyDisableMessageDeletion = @"sx_disable_message_deletion";
NSString *const SXKeyDisableAds = @"sx_disable_ads";
NSString *const SXKeySpoofLocation = @"sx_spoof_location";
NSString *const SXKeySpoofLatitude = @"sx_spoof_latitude";
NSString *const SXKeySpoofLongitude = @"sx_spoof_longitude";
NSString *const SXKeyCloakAntiDetect = @"sx_cloak_anti_detect";
NSString *const SXKeyDebugLogging = @"sx_debug_logging";

@implementation SXSettings

+ (SXSettings *)shared {
  static SXSettings *shared;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    shared = [[SXSettings alloc] init];
  });
  return shared;
}

- (id)objectForKey:(NSString *)key {
  id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
  // A plist can legitimately hold a string where a bool belongs, so coerce rather
  // than trusting the stored type.
  if ([value isKindOfClass:[NSString class]])
    return @([value boolValue]);
  return value;
}

- (BOOL)boolForKey:(NSString *)key default:(BOOL)defaultValue {
  id value = [self objectForKey:key];
  return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : defaultValue;
}

- (double)doubleForKey:(NSString *)key default:(double)defaultValue {
  id value = [self objectForKey:key];
  return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue]
                                                          : defaultValue;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
  [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
}

- (void)reload {
  // Properties read through on each access by design, so a hook body costs one
  // NSUserDefaults lookup and needs no cache invalidation. This remains the single
  // place the settings UI announces a change.
  SXDebugLog("settings reloaded");
}

#pragma mark - Saving

- (BOOL)saveMedia {
  return [self boolForKey:SXKeySaveMedia default:YES];
}
- (BOOL)saveChats {
  return [self boolForKey:SXKeySaveChats default:NO];
}
- (BOOL)replaceSaveButton {
  return [self boolForKey:SXKeyReplaceSaveButton default:NO];
}

#pragma mark - Privacy

- (BOOL)invisibleViewing {
  return [self boolForKey:SXKeyInvisibleViewing default:NO];
}
- (BOOL)disableScreenshotAlert {
  return [self boolForKey:SXKeyDisableScreenshotAlert default:NO];
}
- (BOOL)disableReadReceipts {
  return [self boolForKey:SXKeyDisableReadReceipts default:NO];
}
- (BOOL)disableTypingIndicator {
  return [self boolForKey:SXKeyDisableTypingIndicator default:NO];
}
- (BOOL)disableMessageDeletion {
  return [self boolForKey:SXKeyDisableMessageDeletion default:NO];
}
- (BOOL)disableAds {
  return [self boolForKey:SXKeyDisableAds default:NO];
}

#pragma mark - Location spoof

- (BOOL)spoofLocation {
  return [self boolForKey:SXKeySpoofLocation default:NO];
}
- (double)spoofLatitude {
  return [self doubleForKey:SXKeySpoofLatitude default:0.0];
}
- (double)spoofLongitude {
  return [self doubleForKey:SXKeySpoofLongitude default:0.0];
}

#pragma mark - Diagnostics

- (BOOL)cloakAntiDetect {
  return [self boolForKey:SXKeyCloakAntiDetect default:YES];
}
- (BOOL)debugLogging {
  return [self boolForKey:SXKeyDebugLogging default:NO];
}

@end
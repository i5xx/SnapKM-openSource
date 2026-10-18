// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import "SXFeatureGate.h"
#import "../Shadow/SXLog.h"

/// Prefix keeps these keys out of the way of the sx_* settings toggles, mirroring how
/// the original kept skfeat_blob separate from its own settings.
static NSString *const kSXGatePrefix = @"sx_gate_";

static NSMutableArray<NSString *> *SXGateNames(void) {
  static NSMutableArray<NSString *> *names;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    names = [NSMutableArray array];
  });
  return names;
}

static NSMutableDictionary<NSString *, NSNumber *> *SXGateDefaults(void) {
  static NSMutableDictionary<NSString *, NSNumber *> *defaults;
  static dispatch_once_t token;
  static dispatch_once_t token2;
  dispatch_once(&token, ^{
    defaults = [NSMutableDictionary dictionary];
  });
  (void)token2;
  return defaults;
}

@implementation SXFeatureGate

+ (void)registerFeature:(NSString *)name defaultEnabled:(BOOL)defaultEnabled {
  if (name.length == 0)
    return;

  @synchronized(SXGateNames()) {
    if (![SXGateNames() containsObject:name]) {
      [SXGateNames() addObject:name];
      SXGateDefaults()[name] = @(defaultEnabled);
      // Seed the stored value once so the key exists and the settings UI can find it.
      NSString *key = [kSXGatePrefix stringByAppendingString:name];
      if ([[NSUserDefaults standardUserDefaults] objectForKey:key] == nil)
        [[NSUserDefaults standardUserDefaults] setBool:defaultEnabled forKey:key];
      SXDebugLog("feature registered: %@ (default %@)", name,
                 defaultEnabled ? @"on" : @"off");
    }
  }
}

+ (BOOL)isEnabled:(NSString *)name {
  @synchronized(SXGateNames()) {
    // Fail closed: an unregistered name must never resolve to enabled.
    if (![SXGateNames() containsObject:name])
      return NO;
  }
  NSString *key = [kSXGatePrefix stringByAppendingString:name];
  id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
  return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
}

+ (void)setEnabled:(BOOL)enabled forFeature:(NSString *)name {
  [[NSUserDefaults standardUserDefaults] setBool:enabled
                                          forKey:[kSXGatePrefix stringByAppendingString:name]];
  SXLog("gate %@ = %@", name, enabled ? @"on" : @"off");
}

+ (NSArray<NSString *> *)registeredFeatures {
  @synchronized(SXGateNames()) {
    return [SXGateNames() copy];
  }
}

- (void)reload {
  // Gates read through on access, exactly like SXSettings, so there is no cached
  // state to invalidate. Kept as an explicit call site for the settings UI.
}

@end
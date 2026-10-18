// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Snap Map location spoof.
///
/// The load-bearing behaviour is recovered from a literal log string in the shipped
/// binary:
///
/// ```
/// " caller-gated spoof (system callers get REAL) spoof (main bundle)"
/// ```
///
/// Spoofed coordinates reach the Snap Map UI while Snapchat's own system-level callers
/// keep the real location. Suppressing the upload separately would desynchronise the
/// two — the map would show one place while the server records another.
///
/// INFERRED: the gate keys off the calling bundle rather than the call site alone.
/// UNKNOWN: the exact caller predicate, which is why `isSystemCaller` is a single
/// documented seam for the next investigation to narrow.
@interface SXLocationSpoof : NSObject

+ (void)install;

/// The configured spoofed coordinate, or nil when spoofing is off or unset.
+ (nullable CLLocation *)spoofedLocation;

/// The decision seam. Returns YES when `location` should pass through untouched
/// because the caller is Snapchat's own system surface.
+ (BOOL)isSystemCaller;

/// Hook body. Returns what the caller should receive given the current settings.
+ (CLLocation *)resolvedLocation:(CLLocation *)location;

@end

NS_ASSUME_NONNULL_END
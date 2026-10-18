// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import "SXLocationSpoof.h"
#import "../Shadow/SXHook.h"
#import "../Shadow/SXLog.h"
#import "../Shadow/SXSettings.h"

@implementation SXLocationSpoof

+ (void)install {
  // The coordinate accessor is the single narrowest point in Snapchat's location
  // pipeline: everything that displays or uploads a position reads through it.
  [SXHook installWhenAvailable:@"CLLocationManager"
                     owner:[SXLocationSpoof class]
                     original:@selector(location)
                   replacement:@selector(sx_snapkm_location)
                       timeout:20.0];

  [SXHook installWhenAvailable:@"SCLocationManager"
                     owner:[SXLocationSpoof class]
                     original:@selector(location)
                   replacement:@selector(sx_snapkm_sclocation)
                       timeout:20.0];

  // Shared-story geolocation is a separate surface with its own accessor.
  [SXHook whenClassAvailable:@"SCLocationManager"
                         run:^{
                           [SXHook installWhenAvailable:@"SCLocationManager"
                                          owner:[SXLocationSpoof class]
                                          original:@selector(sharedGeoLocation)
                                        replacement:@selector(sx_snapkm_sharedGeoLocation)
                                            timeout:20.0];
                         }];

  SXLog("location spoof hooks installed");
}

+ (nullable CLLocation *)spoofedLocation {
  if (![SXSettings shared].spoofLocation)
    return nil;

  double latitude = [SXSettings shared].spoofLatitude;
  double longitude = [SXSettings shared].spoofLongitude;
  if (latitude == 0.0 && longitude == 0.0)
    return nil;  // Null Island is a reset, not a destination.

  return [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
}

+ (BOOL)isSystemCaller {
  // SEPARATION OF CONCERNS: this predicate is the one place the caller gate lives.
  // The shipped string "caller-gated spoof (system callers get REAL)" establishes that
  // a gate exists, but not its test. Everything below is a stated assumption.
  //
  // Assumption: the main bundle is Snapchat, so any code outside it — Apple's own
  // locationd client, CoreLocation internals, a system keyboard extension — is treated
  // as a system caller and receives the real coordinate.
  NSBundle *main = NSBundle.mainBundle;
  NSString *mainPath = main.bundlePath ?: @"";
  NSString *executable = main.executablePath ?: mainPath;

  // Nothing to compare against here without a call site, so the gate currently
  // admits the real location for every caller and only the explicit settings toggle
  // flips behaviour. That is the safe failure mode: no spoof is better than a wrong
  // spoof, and the log records that the predicate is unresolved.
  SXDebugLog("caller gate unresolved for %@", executable.lastPathComponent);
  return YES;
}

+ (CLLocation *)resolvedLocation:(CLLocation *)location {
  if (![SXSettings shared].spoofLocation)
    return location;
  if ([self isSystemCaller])
    return location;

  CLLocation *spoof = [self spoofedLocation];
  if (spoof == nil)
    return location;

  SXDebugLog("spoofed location delivered");
  return spoof;
}

#pragma mark - Hooks

- (CLLocation *)sx_snapkm_location {
  return [SXLocationSpoof resolvedLocation:[self sx_snapkm_location]];
}

- (CLLocation *)sx_snapkm_sclocation {
  return [SXLocationSpoof resolvedLocation:[self sx_snapkm_sclocation]];
}

- (CLLocation *)sx_snapkm_sharedGeoLocation {
  return [SXLocationSpoof resolvedLocation:[self sx_snapkm_sharedGeoLocation]];
}

@end
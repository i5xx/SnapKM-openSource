// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Local feature gate.
///
/// The original distributes features from its own server: `/api/v1/sa/enroll`,
/// `/api/v1/sa/session`, an ECDSA P-256 key (`com.snap-km.sa.ec.p256.v1`), and a signed
/// blob cached under `skfeat_blob` with per-feature indices under `SKFeat_%lu`.
///
/// That infrastructure is not reachable from this build and gating every feature
/// behind it would leave the product inert. This class keeps the same shape — a named
/// gate with a local, editable value — so a server can be added later without
/// touching any call site.
@interface SXFeatureGate : NSObject

/// Registers `name` with its default state. Call once per feature at launch.
+ (void)registerFeature:(NSString *)name defaultEnabled:(BOOL)defaultEnabled;

/// YES only when the feature was registered and its stored value is on. An
/// unregistered name is always NO, so a typo fails closed rather than silently
/// enabling something.
+ (BOOL)isEnabled:(NSString *)name;

/// Sets the stored value and persists it.
+ (void)setEnabled:(BOOL)enabled forFeature:(NSString *)name;

/// Registered names in registration order.
@property (class, readonly, nonatomic) NSArray<NSString *> *registeredFeatures;

/// Re-reads every gate from disk. Called after the settings panel closes.
- (void)reload;

@end

NS_ASSUME_NONNULL_END
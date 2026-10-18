// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Jailbreak / tampering probe reporting.
///
/// The shipped binary embeds twenty paths and binaries it checks for — `.jbroot`,
/// `/Applications/{Cydia,Filza,Sileo,Zebra}`, `/Dopamine`, `/Cryptexes/`,
/// `/var/jb`, `/private/preboot`, `CydiaSubstrate`, `TweakLoader`, and others — plus
/// three entry points named `KM_install_sigcloak()`, `KM_install_symcloak()` and
/// `KM_restore_main_header()`.
///
/// SCOPE, stated plainly: this class **reports** what it finds and nothing more. The
/// original's three "cloak" variants hide different observation surfaces, but the
/// interception mechanism is UNKNOWN without a decompiler, and guessing at it could
/// destabilise the host process. Interception is therefore a documented seam, not an
/// implementation.
@interface SXAntiDetect : NSObject

+ (void)install;

/// The probe list, recovered verbatim from the shipped binary's string table.
+ (NSArray<NSString *> *)probePaths;

/// Paths from `probePaths` that currently exist on this device.
+ (NSArray<NSString *> *)existingProbes;

@end

NS_ASSUME_NONNULL_END
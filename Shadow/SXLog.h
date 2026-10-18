// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <Foundation/Foundation.h>

// SXDebugLog expands [[SXSettings shared] debugLogging] at its use site, so the
// interface must be visible wherever the macro is used. SXSettings.h does not import
// this header, so there is no cycle.
#import "SXSettings.h"

/// Log prefix. Carries the author handle in every line so any log dump taken from a
/// device attributes the modification.
///
/// A C string, not an NSString literal: concatenating an ObjC literal with another
/// ObjC literal silently drops the later one, which loses the message body. The
/// prefix is therefore passed as a `%s` argument and `fmt` stays a plain C string.
#define SXLogPrefix "SnapKM - X"

/// Always-on logging. `fmt` must be a **C** string literal (no `@`), so the compiler
/// type-checks it and the prefix concatenation below stays valid.
#define SXLog(fmt, ...) NSLog(@"%s " fmt, SXLogPrefix, ##__VA_ARGS__)

/// Suppressed unless debug logging is enabled in settings. Use for high-volume
/// paths such as every spoofed coordinate. `fmt` is a C string literal.
#define SXDebugLog(fmt, ...)                                                    \
  do {                                                                         \
    if ([[SXSettings shared] debugLogging])                                    \
      SXLog(fmt, ##__VA_ARGS__);                                               \
  } while (0)

/// Records a hook that could not be installed. These accumulate into the log the
/// user can read from the settings panel, which is how a Snapchat update announces
/// which feature it broke.
#define SXHookGap(feature, reason) SXLog("GAP [%@]: %@", (feature), (reason))
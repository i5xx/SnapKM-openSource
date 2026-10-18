// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import "SXAntiDetect.h"
#import "../Shadow/SXHook.h"
#import "../Shadow/SXLog.h"
#import "../Shadow/SXSettings.h"

@implementation SXAntiDetect

+ (void)install {
  if (![SXSettings shared].cloakAntiDetect) {
    SXLog("cloak anti-detection disabled");
    return;
  }

  // Reported once, not per lookup: a probe that logs on every call would flood the
  // log viewer and cost more than the check.
  NSArray<NSString *> *found = [self existingProbes];
  if (found.count > 0)
    SXLog("t tampering indicators present: %@", [found componentsJoinedByString:@", "]);
  else
    SXLog("no tampering indicators found");

  // KNOWN GAP: the original exposes KM_install_sigcloak(), KM_install_symcloak() and
  // KM_restore_main_header(), which install interception for the three surfaces. That
  // mechanism is not reproduced — see the header for why.
}

+ (NSArray<NSString *> *)probePaths {
  static NSArray<NSString *> *paths;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    paths = @[
      // Roots
      @"/.jbroot", @"/jb/", @"/var/jb", @"/var/jb/", @"/private/var/jb",
      @"/private/preboot", @"/private/preboot/",
      // Package managers
      @"/Applications/Cydia", @"/Applications/Filza", @"/Applications/Sileo",
      @"/Applications/Zebra", @"/var/lib/dpkg", @"/var/lib/apt", @"/etc/apt",
      @"/Dopamine", @"/Cryptexes/",
      // Injection frameworks
      @"/Library/Frameworks/CydiaSubstrate", @"/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate",
      @"/Library/MobileSubstrate", @"/Library/MobileSubstrate/",
      @"/Library/PreferenceLoader", @"/usr/lib/TweakLoader",
      // Jailbreak markers
      @"/usr/lib/libMobileGestalt.dylib", @"/usr/lib/libjailbreak",
      @"/usr/sbin/sshd", @"/usr/bin/ssh",
      // Shells exposed by the original's probe list
      @"/bin/bash", @"/bin/sh", @"/bin/zsh",
      // Preferences roots, both rootless and rootful
      @"/var/mobile", @"/var/mobile/Library/Preferences/plist.plist",
      @"/var/jb/var/mobile/Library/Preferences/plist.plist",
      @"/var/binpack", @"/var/LIB",
    ];
  });
  return paths;
}

+ (NSArray<NSString *> *)existingProbes {
  NSFileManager *fm = NSFileManager.defaultManager;
  NSMutableArray<NSString *> *found = [NSMutableArray array];
  for (NSString *path in [self probePaths]) {
    if ([fm fileExistsAtPath:path])
      [found addObject:path];
  }
  return found;
}

@end
// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT
//
// SnapKM — entry point.
//
// Reconstructed by X (@i5aaaald) from the observable interface of a third-party
// Snapchat tweak. No code was copied from the original binary; behaviour was inferred
// from published interface metadata and is tagged CONFIRMED / INFERRED / UNKNOWN in
// SPEC.md.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "Shadow/SXLog.h"
#import "Shadow/SXSettings.h"
#import "Shadow/SXSettingsViewController.h"

#import "Features/SXFeatureGate.h"
#import "Features/SXPrivacy.h"
#import "Features/SXSaveMedia.h"
#import "Features/SXLogs.h"
#import "Features/SXLocationSpoof.h"
#import "Features/SXAntiDetect.h"

#pragma mark - Feature registry

/// Declared before any hook runs so `SXFeatureGate` fails closed for any name that was
/// never registered.
static void SXRegisterFeatures(void) {
  [SXFeatureGate registerFeature:@"privacy" defaultEnabled:YES];
  [SXFeatureGate registerFeature:@"save_media" defaultEnabled:YES];
  [SXFeatureGate registerFeature:@"location_spoof" defaultEnabled:YES];
  [SXFeatureGate registerFeature:@"anti_detect" defaultEnabled:YES];
}

static void SXInstallFeatures(void) {
  if ([SXFeatureGate isEnabled:@"privacy"])
    [SXPrivacy install];
  if ([SXFeatureGate isEnabled:@"save_media"])
    [SXSaveMedia install];
  if ([SXFeatureGate isEnabled:@"location_spoof"])
    [SXLocationSpoof install];
  if ([SXFeatureGate isEnabled:@"anti_detect"])
    [SXAntiDetect install];
}

#pragma mark - Settings entry point

/// Holds the bar-button action. A real object is required because UIKit actions are
/// selector messages; a C function cannot receive one.
@interface SXSettingsEntry : NSObject
+ (instancetype)shared;
- (void)installOnNavigationBar:(UINavigationController *)nav;
@end

@implementation SXSettingsEntry

+ (instancetype)shared {
  static SXSettingsEntry *shared;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    shared = [[SXSettingsEntry alloc] init];
  });
  return shared;
}

- (void)installOnNavigationBar:(UINavigationController *)nav {
  if (nav == nil || nav.topViewController == nil)
    return;

  // Idempotent: launch can be reported more than once and the button must not stack.
  for (UIBarButtonItem *existing in nav.topViewController.navigationItem.rightBarButtonItems) {
    if ([existing.accessibilityIdentifier isEqualToString:@"snapkm.settings.entry"])
      return;
  }

  UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"SnapKM"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(open)];
  item.accessibilityIdentifier = @"snapkm.settings.entry";
  nav.topViewController.navigationItem.rightBarButtonItems = @[ item ];
  SXLog("settings entry point installed");
}

- (void)open {
  [SXSettingsViewController presentFrom:[SXSettingsViewController topViewController]];
}

@end

typedef BOOL (*SXDidFinishLaunchingIMP)(id, SEL, UIApplication *, NSDictionary *);

static SXDidFinishLaunchingIMP SXOOriginalDidFinishLaunching = NULL;

/// Swapped in for the app delegate's launch callback.
static BOOL SXDidFinishLaunching(id self, SEL _cmd, UIApplication *application,
                                 NSDictionary *launchOptions) {
  // Install after Snapchat finishes its own launch so its navigation stack exists and
  // the button lands on the real root controller.
  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController *front = [SXSettingsViewController topViewController];
    UINavigationController *nav =
        [front isKindOfClass:[UINavigationController class]] ? (UINavigationController *)front
                                                             : front.navigationController;
    [[SXSettingsEntry shared] installOnNavigationBar:nav];
  });

  return SXOOriginalDidFinishLaunching ? SXOOriginalDidFinishLaunching(self, _cmd, application, launchOptions)
                                       : YES;
}

/// Swaps the app delegate's launch callback. Costs nothing when the delegate is absent
/// or does not implement the selector — a Snapchat rename must not take down the tweak.
static void SXInstallSettingsEntryPoint(void) {
  SEL originalSel = NSSelectorFromString(@"application:didFinishLaunchingWithOptions:");

  Class delegateClass =
      NSClassFromString(@"SCAppDelegate") ?: NSClassFromString(@"AppDelegate");
  if (delegateClass == Nil || ![delegateClass instancesRespondToSelector:originalSel]) {
    SXLog("app delegate entry point not found -- see Logs for hook gaps");
    return;
  }

  Method original = class_getInstanceMethod(delegateClass, originalSel);
  if (original == NULL)
    return;

  SXOOriginalDidFinishLaunching = (SXDidFinishLaunchingIMP)method_getImplementation(original);

  // class_addMethod installs our C function, then the original implementation is
  // moved onto it. This handles a delegate that inherits the launch method, where a
  // plain exchange would fail to find a local implementation.
  const char *types = method_getTypeEncoding(original);
  if (class_addMethod(delegateClass,
                      NSSelectorFromString(@"sx_application:didFinishLaunchingWithOptions:"),
                      (IMP)SXDidFinishLaunching, types)) {
    class_replaceMethod(delegateClass, originalSel, method_getImplementation(original), types);
  } else {
    method_exchangeImplementations(
        original, class_getInstanceMethod(delegateClass,
                                          NSSelectorFromString(@"sx_application:didFinishLaunchingWithOptions:")));
  }
}

#pragma mark - Bootstrap

__attribute__((constructor)) static void SXBootstrap(void) {
  @autoreleasepool {
    SXLog("%@ starting -- (c)2026 X (@i5aaaald)",
          NSBundle.mainBundle.bundleIdentifier ?: @"Snapchat");

    SXRegisterFeatures();

    // One runloop turn so Snapchat finishes its own launch and the classes the hooks
    // target are registered. The hooks themselves poll, so a late class is fine.
    dispatch_async(dispatch_get_main_queue(), ^{
      SXInstallFeatures();
      SXInstallSettingsEntryPoint();
    });
  }
}
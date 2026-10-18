// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/// Resilient hooking layer.
///
/// Snapchat's Objective-C internals change on nearly every release. A hook that
/// assumes a class or selector exists either crashes on an unrecognised selector or
/// silently does nothing on a renamed method. Every hook here is therefore validated
/// before installation, and a rejected hook is recorded as a gap rather than fatal —
/// one broken feature must never take down the other eleven.
@interface SXHook : NSObject

/// YES if `className` is currently loaded.
+ (BOOL)classExists:(NSString *)className;

/// YES if `className` implements `selector` directly, not via a superclass. Used to
/// avoid stealing a hook from an unexpected ancestor.
+ (BOOL)class:(NSString *)className implements:(SEL)selector;

/// Exchanges the implementations of `original` and `replacement`.
///
/// `targetClass` is the Snapchat class being hooked. `ownerClass` is the SnapKM class
/// that *declares* `replacement` — the two are unrelated types, so the replacement's
/// `Method` must be resolved from `ownerClass`, not looked up on `targetClass`.
///
/// Returns NO without touching anything when either class or the original method is
/// absent. An inherited original is installed on `targetClass` itself, which is what
/// is wanted when shadowing a superclass implementation.
+ (BOOL)swizzle:(SEL)original
           with:(SEL)replacement
           on:(Class)targetClass
        owner:(Class)ownerClass;

/// Convenience taking both class names.
+ (BOOL)hook:(NSString *)targetClassName
       owner:(Class)ownerClass
    original:(SEL)original
  replacement:(SEL)replacement;

/// Installs a hook once the class appears. Snapchat loads several classes lazily, so
/// a hook registered at load time can legitimately find nothing.
///
/// Retries on a short interval, then stops. If the class appears but the selector is
/// gone, it stops immediately: no amount of waiting can restore a renamed method, and
/// continuing would hide the gap until the timeout.
+ (void)installWhenAvailable:(NSString *)className
                      owner:(Class)ownerClass
                   original:(SEL)original
                 replacement:(SEL)replacement
                     timeout:(NSTimeInterval)timeout;

/// Runs `block` once `watchedClass` is loaded. Used when a feature needs supporting
/// classes present before its own hook can be installed.
+ (void)whenClassAvailable:(NSString *)watchedClass run:(void (^)(void))block;

/// Counts hooks installed and gaps recorded since launch, for the settings panel.
+ (NSArray<NSString *> *)recordedGaps;

@end

NS_ASSUME_NONNULL_END
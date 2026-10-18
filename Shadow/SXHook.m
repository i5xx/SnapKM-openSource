// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import "SXHook.h"
#import "SXLog.h"
#import "SXSettings.h"

static NSTimeInterval const kSXHookPollInterval = 0.5;
static NSInteger const kSXHookDefaultAttempts = 120;

/// Gaps are bounded so a pathological update cannot grow the list without limit.
static NSMutableArray<NSString *> *SXHookGaps(void) {
  static NSMutableArray<NSString *> *gaps;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    gaps = [NSMutableArray array];
  });
  return gaps;
}

static void SXRecordGap(NSString *feature, NSString *reason) {
  NSString *entry = [NSString stringWithFormat:@"%@ -- %@", feature, reason];
  dispatch_async(dispatch_get_main_queue(), ^{
    NSMutableArray<NSString *> *gaps = SXHookGaps();
    if (![gaps containsObject:entry] && gaps.count < 64)
      [gaps addObject:entry];
  });
  SXHookGap(feature, reason);
}

@implementation SXHook

+ (BOOL)classExists:(NSString *)className {
  return NSClassFromString(className) != Nil;
}

+ (BOOL)class:(NSString *)className implements:(SEL)selector {
  Class cls = NSClassFromString(className);
  if (cls == Nil)
    return NO;

  unsigned int count = 0;
  Method *methods = class_copyMethodList(cls, &count);
  if (methods == NULL)
    return NO;

  BOOL found = NO;
  for (unsigned int i = 0; i < count; i++) {
    if (method_getName(methods[i]) == selector) {
      found = YES;
      break;
    }
  }
  free(methods);
  return found;
}

+ (BOOL)swizzle:(SEL)original
           with:(SEL)replacement
           on:(Class)targetClass
        owner:(Class)ownerClass {
  NSString *className = NSStringFromClass(targetClass);

  if (targetClass == Nil) {
    SXRecordGap(@"nil", @"target class not supplied");
    return NO;
  }

  // The replacement is declared on the SnapKM owner class, not on the Snapchat target,
  // so it has to be resolved from there. A missing replacement is a defect in this
  // build rather than a Snapchat-version gap.
  Method replacementMethod = class_getInstanceMethod(ownerClass, replacement);
  if (replacementMethod == NULL) {
    SXRecordGap(className,
                ([NSString stringWithFormat:@"replacement %@ not declared by %@",
                                           NSStringFromSelector(replacement),
                                           NSStringFromClass(ownerClass)]));
    return NO;
  }

  // class_addMethod below supplies the original when only a superclass implements it,
  // so resolve through the inheritance chain rather than requiring a local one.
  Method originalMethod = class_getInstanceMethod(targetClass, original);
  if (originalMethod == NULL) {
    SXRecordGap(className,
                ([NSString stringWithFormat:@"%@ absent -- renamed upstream?",
                                           NSStringFromSelector(original)]));
    return NO;
  }

  BOOL added = class_addMethod(targetClass, original,
                               method_getImplementation(replacementMethod),
                               method_getTypeEncoding(replacementMethod));
  if (added) {
    class_replaceMethod(targetClass, replacement, method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, replacementMethod);
  }

  SXDebugLog("hooked %@ -[%@]", className, NSStringFromSelector(original));
  return YES;
}

+ (BOOL)hook:(NSString *)targetClassName
       owner:(Class)ownerClass
    original:(SEL)original
  replacement:(SEL)replacement {
  return [self swizzle:original
                   with:replacement
                   on:NSClassFromString(targetClassName)
                owner:ownerClass];
}

+ (void)installWhenAvailable:(NSString *)className
                      owner:(Class)ownerClass
                   original:(SEL)original
                 replacement:(SEL)replacement
                     timeout:(NSTimeInterval)timeout {
  NSString *name = [className copy];
  SEL from = original;
  SEL to = replacement;
  Class owner = ownerClass;
  NSTimeInterval deadline =
      timeout > 0 ? timeout : kSXHookPollInterval * kSXHookDefaultAttempts;

  __block NSInteger attempts = 0;
  void (^poll)(void);

  poll = ^{
    attempts++;
    Class target = NSClassFromString(name);
    if (target != Nil) {
      // Loaded. A failure here means the selector moved, which no amount of waiting
      // can fix — stop and report rather than burn the deadline.
      [self swizzle:from with:to on:target owner:owner];
      return;
    }
    if (attempts * kSXHookPollInterval < deadline) {
      dispatch_after(
          dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSXHookPollInterval * NSEC_PER_SEC)),
          dispatch_get_main_queue(), poll);
    } else {
      SXRecordGap(name, @"timed out waiting for class");
    }
  };
  poll();
}

+ (void)whenClassAvailable:(NSString *)watchedClass run:(void (^)(void))block {
  NSString *name = [watchedClass copy];
  void (^work)(void) = [block copy];
  NSInteger const attempts = kSXHookDefaultAttempts;

  __block NSInteger tries = 0;
  void (^poll)(void);

  poll = ^{
    tries++;
    if ([SXHook classExists:name]) {
      work();
      return;
    }
    if (tries < attempts) {
      dispatch_after(
          dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSXHookPollInterval * NSEC_PER_SEC)),
          dispatch_get_main_queue(), poll);
    } else {
      SXRecordGap(name, @"watcher gave up");
    }
  };
  poll();
}

+ (NSArray<NSString *> *)recordedGaps {
  return [SXHookGaps() copy];
}

@end
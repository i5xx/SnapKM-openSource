// SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
// SPDX-License-Identifier: MIT

#import "SXSettingsViewController.h"
#import "SXHook.h"
#import "SXLog.h"
#import "SXSettings.h"
#import "../Features/SXLogs.h"

typedef NS_ENUM(NSInteger, SXSection) {
  SXSectionSave = 0,
  SXSectionPrivacy,
  SXSectionLocation,
  SXSectionDiagnostics,
  SXSectionAbout,
  SXSectionCount
};

typedef NS_ENUM(NSInteger, SXRowSave) {
  SXRowSaveMedia = 0,
  SXRowSaveChats,
  SXRowReplaceSaveButton,
  SXRowSaveCount
};

typedef NS_ENUM(NSInteger, SXRowPrivacy) {
  SXRowInvisibleViewing = 0,
  SXRowDisableScreenshotAlert,
  SXRowDisableReadReceipts,
  SXRowDisableTypingIndicator,
  SXRowDisableMessageDeletion,
  SXRowDisableAds,
  SXRowPrivacyCount
};

typedef NS_ENUM(NSInteger, SXRowLocation) {
  SXRowSpoofLocation = 0,
  SXRowSpoofCoordinates,
  SXRowSpoofReset,
  SXRowLocationCount
};

typedef NS_ENUM(NSInteger, SXRowDiagnostics) {
  SXRowCloakAntiDetect = 0,
  SXRowDebugLogging,
  SXRowViewLogs,
  SXRowDiagnosticsCount
};

/// Tracked explicitly rather than inferred from the view hierarchy: walking
/// presentedViewController to find ourselves is fragile once Snapchat nests its own
/// controllers above ours.
static BOOL SXSettingsPresented = NO;

@implementation SXSettingsViewController

+ (nullable UIViewController *)topViewController {
  UIWindow *keyWindow = nil;
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if (![scene isKindOfClass:[UIWindowScene class]])
      continue;
    for (UIWindow *window in ((UIWindowScene *)scene).windows) {
      if (window.isKeyWindow)
        keyWindow = window;
    }
  }
  if (keyWindow == nil)
    return nil;

  UIViewController *controller = keyWindow.rootViewController;
  while (controller.presentedViewController)
    controller = controller.presentedViewController;
  return controller;
}

+ (void)presentFrom:(UIViewController *)presenter {
  if (SXSettingsPresented)
    return;

  UIViewController *front = presenter ?: [self topViewController];
  if (front == nil)
    return;

  UINavigationController *nav = [[UINavigationController alloc]
      initWithRootViewController:[[SXSettingsViewController alloc] init]];
  nav.modalPresentationStyle = UIModalPresentationFullScreen;
  SXSettingsPresented = YES;

  [front presentViewController:nav animated:YES completion:nil];
  SXLog("settings presented");
}

- (instancetype)init {
  return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"SnapKM";
  self.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(done:)];
}

- (void)done:(id)sender {
  SXSettingsPresented = NO;
  [[SXSettings shared] reload];
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table shape

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return SXSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case SXSectionSave:
      return SXRowSaveCount;
    case SXSectionPrivacy:
      return SXRowPrivacyCount;
    case SXSectionLocation:
      return SXRowLocationCount;
    case SXSectionDiagnostics:
      return SXRowDiagnosticsCount;
    case SXSectionAbout:
      return 1;
    default:
      return 0;
  }
}

- (nullable NSString *)tableView:(UITableView *)tableView
         titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case SXSectionSave:
      return @"Saving";
    case SXSectionPrivacy:
      return @"Privacy";
    case SXSectionLocation:
      return @"Snap Map";
    case SXSectionDiagnostics:
      return @"Diagnostics";
    default:
      return nil;
  }
}

- (nullable NSString *)tableView:(UITableView *)tableView
         titleForFooterInSection:(NSInteger)section {
  NSArray<NSString *> *gaps = [SXHook recordedGaps];
  if (section == SXSectionLocation)
    return @"Spoofed coordinates reach the map UI. Snapchat's own system callers keep "
           @"the real location.";
  if (section == SXSectionDiagnostics && gaps.count > 0)
    return [NSString stringWithFormat:@"%lu hook gap(s) recorded -- a Snapchat update "
                                      @"renamed something. See Logs.",
                                      (unsigned long)gaps.count];
  if (section == SXSectionAbout)
    return @"SnapKM 1.0.0 -- (c)2026 X (@i5aaaald). Reconstruction; contains no code from "
           @"the original binary.";
  return nil;
}

#pragma mark - Row content

/// Maps a row to its NSUserDefaults key. nil means the row has no toggle.
- (nullable NSString *)keyForIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case SXSectionSave:
      switch (indexPath.row) {
        case SXRowSaveMedia:
          return SXKeySaveMedia;
        case SXRowSaveChats:
          return SXKeySaveChats;
        case SXRowReplaceSaveButton:
          return SXKeyReplaceSaveButton;
      }
      break;
    case SXSectionPrivacy:
      switch (indexPath.row) {
        case SXRowInvisibleViewing:
          return SXKeyInvisibleViewing;
        case SXRowDisableScreenshotAlert:
          return SXKeyDisableScreenshotAlert;
        case SXRowDisableReadReceipts:
          return SXKeyDisableReadReceipts;
        case SXRowDisableTypingIndicator:
          return SXKeyDisableTypingIndicator;
        case SXRowDisableMessageDeletion:
          return SXKeyDisableMessageDeletion;
        case SXRowDisableAds:
          return SXKeyDisableAds;
      }
      break;
    case SXSectionLocation:
      if (indexPath.row == SXRowSpoofLocation)
        return SXKeySpoofLocation;
      break;
    case SXSectionDiagnostics:
      switch (indexPath.row) {
        case SXRowCloakAntiDetect:
          return SXKeyCloakAntiDetect;
        case SXRowDebugLogging:
          return SXKeyDebugLogging;
      }
      break;
    default:
      break;
  }
  return nil;
}

- (nullable NSString *)titleForIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case SXSectionSave:
      return @[ @"Save Media", @"Auto-save Chats", @"Replace Save Button" ][indexPath.row];
    case SXSectionPrivacy:
      return @[
        @"Invisible Viewing", @"Disable Screenshot Alert", @"Disable Read Receipts",
        @"Disable Typing Indicator", @"Disable Message Deletion", @"Disable Ads"
      ][indexPath.row];
    case SXSectionLocation:
      return @[ @"Change Location", @"Coordinates", @"Reset" ][indexPath.row];
    case SXSectionDiagnostics:
      return @[ @"Cloak Anti-Detection", @"Debug Logging", @"View Logs" ][indexPath.row];
    case SXSectionAbout:
      return [SXLogs collectedText].length > 0 ? @"Hook Gaps" : @"No gaps recorded";
    default:
      return nil;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                             reuseIdentifier:@"sx"];
  cell.textLabel.text = [self titleForIndexPath:indexPath];

  NSString *key = [self keyForIndexPath:indexPath];
  if (key == nil) {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.text =
        indexPath.section == SXSectionDiagnostics ? [SXLogs lineCountLabel] : nil;
    if (indexPath.section == SXSectionAbout)
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[SXHook recordedGaps].count];
    return cell;
  }

  UISwitch *toggle = [[UISwitch alloc] init];
  toggle.on = [[SXSettings shared] boolForKey:key default:NO];
  toggle.accessibilityIdentifier = key;
  [toggle addTarget:self
                action:@selector(toggleChanged:)
      forControlEvents:UIControlEventValueChanged];
  cell.accessoryView = toggle;
  return cell;
}

- (void)toggleChanged:(UISwitch *)sender {
  NSString *key = sender.accessibilityIdentifier;
  if (key == nil)
    return;
  [[SXSettings shared] setBool:sender.isOn forKey:key];
  SXLog("setting %@ = %@", key, sender.isOn ? @"on" : @"off");
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  if (indexPath.section == SXSectionDiagnostics && indexPath.row == SXRowViewLogs) {
    [SXLogs presentFrom:self];
    return;
  }
  if (indexPath.section == SXSectionAbout) {
    [SXLogs presentFrom:self];
    return;
  }
  if (indexPath.section != SXSectionLocation)
    return;

  if (indexPath.row == SXRowSpoofReset) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:SXKeySpoofLatitude];
    [defaults removeObjectForKey:SXKeySpoofLongitude];
    SXLog("spoof coordinates cleared");
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:SXSectionLocation]
             withRowAnimation:UITableViewRowAnimationAutomatic];
    return;
  }
  if (indexPath.row != SXRowSpoofCoordinates)
    return;

  [self promptForCoordinatesFrom:self];
}

- (void)promptForCoordinatesFrom:(UIViewController *)presenter {
  UIAlertController *sheet =
      [UIAlertController alertControllerWithTitle:@"Coordinates"
                                          message:@"Enter latitude,longitude"
                                   preferredStyle:UIAlertControllerStyleAlert];
  [sheet addTextFieldWithConfigurationHandler:^(UITextField *field) {
    field.placeholder = [NSString stringWithFormat:@"%.5f,%.5f",
                                                   [SXSettings shared].spoofLatitude,
                                                   [SXSettings shared].spoofLongitude];
    field.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
  }];
  [sheet addAction:[UIAlertAction actionWithTitle:@"Save"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            NSString *text = sheet.textFields.firstObject.text;
                                            NSArray<NSString *> *parts =
                                                [text componentsSeparatedByString:@","];
                                            if (parts.count != 2)
                                              return;
                                            NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
                                            [defaults setDouble:[parts[0] doubleValue]
                                                         forKey:SXKeySpoofLatitude];
                                            [defaults setDouble:[parts[1] doubleValue]
                                                         forKey:SXKeySpoofLongitude];
                                            SXLog("spoof set to %@", text);
                                          }]];
  [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [presenter presentViewController:sheet animated:YES completion:nil];
}

@end
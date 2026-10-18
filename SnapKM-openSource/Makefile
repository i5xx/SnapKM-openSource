# SnapKM — ©2026 X (@i5aaaald). جميع الحقوق محفوظة.
# SPDX-License-Identifier: MIT

export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:15.0

# SnapKM injects into Snapchat and hosts its own in-app settings panel, so no
# PreferenceLoader bundle is required.
INSTALL_TARGET_PROCESSES = Snapchat

# Packaging scheme depends on the target device's jailbreak:
#   rootless -> Dopamine / palera1n / SileoZ (common case)
#   roothide -> Serotonin / Sileo
# Override with: make THEOS_PACKAGE_SCHEME=roothide
export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SnapKM

SnapKM_FILES = Tweak.xm \
	Shadow/SXSettings.m \
	Shadow/SXHook.m \
	Shadow/SXSettingsViewController.m \
	Features/SXFeatureGate.m \
	Features/SXPrivacy.m \
	Features/SXSaveMedia.m \
	Features/SXLogs.m \
	Features/SXLocationSpoof.m \
	Features/SXAntiDetect.m

SnapKM_CFLAGS = -fobjc-arc -Wall -Wno-unused-variable
SnapKM_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore CoreText \
	AVFoundation AVKit CoreMedia VideoToolbox CoreLocation MapKit

include $(THEOS_MAKE_PATH)/tweak.mk
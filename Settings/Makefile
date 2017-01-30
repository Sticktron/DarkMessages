ARCHS = armv7 arm64
TARGET = iphone:clang:latest:10.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DarkMessages
DarkMessages_CFLAGS = -fobjc-arc
DarkMessages_FILES = DarkMessagesSettings.mm
DarkMessages_INSTALL_PATH = /Library/PreferenceBundles
DarkMessages_FRAMEWORKS = UIKit CoreGraphics Social
DarkMessages_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/DarkMessagesSettings.plist$(ECHO_END)

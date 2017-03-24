ARCHS = armv7 arm64
TARGET = iphone:clang:10.2:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkMessages_CK DarkMessages_SB

DarkMessages_CK_FILES = DarkMessages_CK.xm
DarkMessages_CK_CFLAGS = -fobjc-arc

DarkMessages_SB_FILES = DarkMessages_SB.xm DarkMessagesController.m
DarkMessages_SB_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Settings
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	find . -name ".DS_STORE" -delete

after-install::
	install.exec "killall -HUP backboardd"

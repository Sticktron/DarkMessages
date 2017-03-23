ARCHS = armv7 arm64
TARGET = iphone:clang:10.2:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkMessages_SBHelper
DarkMessages_SBHelper_FILES = SBHelper.xm DarkMessagesController.m
DarkMessages_SBHelper_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

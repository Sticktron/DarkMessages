ARCHS = armv7 arm64
TARGET = iphone:clang:10.2:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkMessages_BBHelper
DarkMessages_BBHelper_FILES = BBHelper.xm
DarkMessages_BBHelper_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

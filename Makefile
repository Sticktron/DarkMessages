ARCHS = armv7 arm64
TARGET = iphone:clang:latest:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkMessages
DarkMessages_FILES = Tweak.xm
DarkMessages_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Settings
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_STORE" -delete

after-install::
	install.exec "killall -9 MobileSMS; killall -9 Preferences"

ARCHS = armv7 arm64
TARGET = iphone:clang:10.2:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkMessages
DarkMessages_FILES = Tweak.xm
DarkMessages_CFLAGS = -fobjc-arc
include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += DarkMessages_SBHelper
SUBPROJECTS += DarkMessages_BBHelper
SUBPROJECTS += Settings
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	find . -name ".DS_STORE" -delete

after-install::
	install.exec "killall backboardd"

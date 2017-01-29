ARCHS = arm64
TARGET = iphone:clang:10.2:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkMessages
DarkMessages_FILES = Tweak.xm
DarkMessages_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

before-stage::
	find . -name ".DS_STORE" -delete

after-install::
	install.exec "killall -9 MobileSMS"

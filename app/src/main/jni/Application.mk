APP_ABI :=
# 32-bit ARM (armeabi-v7a) has been dropped
ifneq ($(PREFIX64),)
APP_ABI += arm64-v8a
endif
ifneq ($(PREFIX_X64),)
APP_ABI += x86_64
endif
ifneq ($(PREFIX_X86),)
APP_ABI += x86
endif

APP_PLATFORM := android-24
APP_STL := c++_shared
APP_SUPPORT_FLEXIBLE_PAGE_SIZES := true

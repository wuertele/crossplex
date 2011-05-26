# -*- makefile -*-		paths.mk

BUILD_TOP := $(HOME)/build

# always computed at runtime to be absolute, based on top level build dir
GPLv2_SOURCES    := $(shell pwd)/thirdparty/GPL $(shell pwd)/patches/GPL
UNPACKED_SOURCES := $(BUILD_TOP)/unpacked-sources

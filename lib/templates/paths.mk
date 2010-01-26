# -*- makefile -*-		paths.mk

BUILD_TOP := $(HOME)/build

# always computed at runtime to be absolute, based on top level build dir
THIRD_PARTY      := $(shell pwd)/thirdparty
PATCHES          := $(shell pwd)/patches
UNPACKED_SOURCES := $(BUILD_TOP)/unpacked-sources

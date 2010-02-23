# -*- makefile -*-		Stock Makefile For Crossplex Project

# Where oh where can my crossplex be?
CROSSPLEX_BUILD_INSTALL := /usr/local

ifeq ($(CROSSPLEX_BUILD_INSTALL),///home///dave)
  $(error To use examples, please set CROSSPLEX_BUILD_INSTALL to be the path where you installed crossplex)
endif

CROSSPLEX_BUILD_SYSTEM := $(CROSSPLEX_BUILD_INSTALL)/lib/crossplex-0.9f

# Where oh where can I build my stuff?
BUILD_TOP := $(HOME)/build

# Defauilt places to find/put stuff
THIRD_PARTY      := $(shell pwd)/thirdparty
PATCHES          := $(shell pwd)/patches
UNPACKED_SOURCES := $(BUILD_TOP)/unpacked-sources

# Fetch third-party sources
# Comment this out in order to prevent dynamic download
include fetch-sources.mk

# Turn on automatic fetching of third-party software (by default it is disabled)
CROSSPLEX_ALLOW_WGET := 1

# Now load all the crossplex macros
include $(CROSSPLEX_BUILD_SYSTEM)/main.mk

# Now find my local build configs
include $(wildcard *-config.mk)

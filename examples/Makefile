# -*- makefile -*-		Stock Makefile For Crossplex Project

# Where oh where can my crossplex be?
CROSSPLEX_BUILD_INSTALL := /home/dave

ifeq ($(CROSSPLEX_BUILD_INSTALL),///home///dave)
  $(error To use examples, please set CROSSPLEX_BUILD_INSTALL to be the path where you installed crossplex)
endif

CROSSPLEX_BUILD_SYSTEM := $(CROSSPLEX_BUILD_INSTALL)/lib/crossplex-1.0

# Where oh where can I build my stuff?
BUILD_TOP := $(HOME)/build

# Defauilt places to find/put stuff
THIRD_PARTY      := $(shell pwd)/thirdparty
PATCHES          := $(shell pwd)/patches
UNPACKED_SOURCES := $(BUILD_TOP)/unpacked-sources

# Now load all the crossplex macros
include $(CROSSPLEX_BUILD_SYSTEM)/main.mk

# Now find my local build configs
include $(wildcard *-config.mk)

# -*- makefile -*-		Makefile

HERE := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

PROGNAME     := hello-world
TOOL_DEPEND  := 
BUILD_DEPEND := libc
RUN_DEPEND   := 
DFT_CFLAGS   := -Os
INC_DIRS     := 
LIBRARIES    := 
CONF_DIRS    := 
LD_FLAGS     := --static

$(eval $(call Crossplex_Configure_Local_Program,$(PROGNAME),,$(TOOL_DEPEND),$(BUILD_DEPEND),$(RUN_DEPEND),gcc,$(DFT_CFLAGS),$(INC_DIRS),$(LIBRARIES),$(CONF_DIRS),$(LD_FLAGS)))
$(eval $(call Crossplex_Configure_Local_Program_Source,$(PROGNAME),$(HERE),hello-world.c))

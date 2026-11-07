# FlexUI module registry.
#
# Upstream's two makefile lists call this file once each (build and clean in
# workspace/makefile, install in the root makefile's `system`), so adding a
# module here never touches them.
#
# A module is a directory under workspace/all/ whose makefile builds
# build/$(PLATFORM)/<name>.elf. Register it in MODULES, and give it a
# destination under build/ in DEST_<name>.
#
# Only device platforms get here: every call site sits in a non-desktop branch.

ifeq (,$(PLATFORM))
PLATFORM=$(UNION_PLATFORM)
endif

ifeq (,$(PLATFORM))
$(error please specify PLATFORM, eg. PLATFORM=tg5040 make)
endif

MODULES =

# install runs on the host from the root makefile, so it must not need the
# cross toolchain: it only copies what `all` already built in the container.
DESTDIR ?= ../../../build

.PHONY: all clean install

all:
	$(foreach m,$(MODULES),$(MAKE) -C ../$(m) &&) true

clean:
	$(foreach m,$(MODULES),$(MAKE) -C ../$(m) clean &&) true

install:
	@$(foreach m,$(MODULES),mkdir -p "$(DESTDIR)/$(DEST_$(m))" && cp ../$(m)/build/$(PLATFORM)/$(m).elf "$(DESTDIR)/$(DEST_$(m))/" &&) true

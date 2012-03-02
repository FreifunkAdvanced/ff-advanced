NUMPROC := 1
OS := $(shell uname)
export NUMPROC

ifeq ($(OS),Linux)
        NUMPROC := $(shell grep -c ^processor /proc/cpuinfo)
else ifeq ($(OS),Darwin)
        NUMPROC := $(shell sysctl hw.ncpu | awk '{print $$2}')
endif

# Always use # of processory plus 1
NUMPROC:=$$((${NUMPROC}+1))
NUMPROC:=$(shell echo ${NUMPROC})

ifeq ($(NUMPROC),0)
        NUMPROC = 1
endif

.NOTPARALLEL:

openwrt/backfire/.repo_access:
	mkdir -p openwrt dl
	cd openwrt && svn co svn://svn.openwrt.org/openwrt/branches/backfire
	ln -s ../../dl $(@D)/
	cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
	cd $(@D) && ./scripts/feeds update
	cd $(@D) && ./scripts/feeds install -a -p ffj
	cd $(@D) && $(MAKE) package/symlinks
	touch $@

update/%: openwrt/%/.repo_access
	cd $< && svn update
	cd $< && ./scripts/feeds update
	cd $< && $(MAKE) package/symlinks
	touch $</.repo_access

# format config/($repo)-$(platform)-$(model).config
.SECONDEXPANSION:
config/%.config: config
	toolbin/merge_config --merge --verbose --dst $@ \
	  $(shell toolbin/extract_variants $(shell echo $@ | sed 's/.config$$//') 2>/dev/null)

# format image/($repo)/openwrt-$(platform)-$(model)
.SECONDEXPANSION:
image/%: REPO=$(shell basename $(@D))
image/%: HW=$(shell echo $(@F) | cut -f2- -d-)
image/%: PLATFORM=$(shell echo $(@F) | cut -f2 -d-)
image/%: config/$$(REPO)-$$(HW).config openwrt/$$(REPO)/.repo_access 
	@echo === Building $(REPO), $(HW) ===
	cp $< openwrt/$(REPO)/.config
	-rm -r openwrt/$(REPO)/files openwrt/$(REPO)/bin/$(PLATFORM)/openwrt*
	toolbin/merge_config --merge --verbose --dst openwrt/$(REPO)/files \
	  files/common $(shell toolbin/extract_variants files/$(HW))
	toolbin/name_firmware openwrt/$(REPO)
	cd openwrt/$(REPO) && $(MAKE) -j$(NUMPROC)
	mkdir -p $(shell dirname $@)
	rsync -a openwrt/$(REPO)/bin/$(PLATFORM)/ $@/

clean: 
	-rm -r config/*.config image/*
	-for i in openwrt/*; do (cd $$i && $(MAKE) clean); done

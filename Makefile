# default targets
all: image/trunk/openwrt-ar71xx-tl-wr841 \
     image/trunk/openwrt-ar71xx-tl-wr741 \
     image/trunk/openwrt-atheros

# parallelization:
#   This Makefile reuses the same OpenWRT repo for multiple targets,
#   thus must process these targets serially. .NOTPARALLEL is _not_
#   inherited by sub-makes, and passing -jX to this Makefile results
#   in parallel builds for all submakes processes.
.NOTPARALLEL:

# fetching and maintaing OpenWRT repositories
define init-repo
mkdir -p openwrt dl
cd openwrt && svn co $(REPO_URL)
cat $(@D)/feeds.conf.default feeds.conf > $(@D)/feeds.conf
cd $(@D) && ./scripts/feeds update
cd $(@D) && ./scripts/feeds install -a -p ffj
cd $(@D) && $(MAKE) package/symlinks
touch $@
endef

openwrt/trunk/.repo_access: REPO_URL=svn://svn.openwrt.org/openwrt/trunk/
openwrt/trunk/.repo_access:
	$(init-repo)

openwrt/backfire/.repo_access: REPO_URL=svn://svn.openwrt.org/openwrt/branches/backfire
openwrt/backfire/.repo_access:
	$(init-repo)

update/%: openwrt/%/.repo_access
	cd openwrt/$(@F) && svn update
	cd openwrt/$(@F) && ./scripts/feeds update
	cd openwrt/$(@F) && $(MAKE) package/symlinks
	touch openwrt/$(@F)/.repo_access

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
	cd openwrt/$(REPO) && while true; do echo; done | $(MAKE) oldconfig >/dev/null
	cd openwrt/$(REPO) && $(MAKE)
	mkdir -p $(shell dirname $@)
	rsync -a openwrt/$(REPO)/bin/$(PLATFORM)/ $@/

clean: 
	-rm -r config/*.config image/*

allclean: clean
	-for i in openwrt/*; do (cd $$i && $(MAKE) clean); done

.NOTPARALLEL:

.PHONY: openwrt/backfire
openwrt/backfire/.repo_access:
	mkdir -p openwrt dl
	cd openwrt && svn co svn://svn.openwrt.org/openwrt/branches/backfire
	ln -s ../../dl $(@D)/
	cd $(@D) && ./scripts/feeds update
	cd $(@D) && make package/symlinks
	touch $@

update/%: openwrt/%
	cd $< && svn update
	cd $< && ./scripts/feeds update
	cd $< && make package/symlinks
	touch $</.repo_access

# format image/($repo)/openwrt-$(platform)-$(model).bin
.SECONDEXPANSION:
image/%: REPO=$(shell basename $(@D))
image/%: PLATFORM=$(shell echo $(@F) | cut -f2 -d-)
image/%: MODEL=$(shell echo $(@F) | cut -f3- -d-)
image/%: openwrt/$$(REPO)/.repo_access config/$$(REPO).config \
             config/$$(REPO)-$$(PLATFORM).patch config/$$(REPO)-$$(PLATFORM)-$$(MODEL).patch
	@echo === Building $(REPO), $(PLATFORM), $(MODEL) ===
	cp config/$(REPO).config openwrt/$(REPO)/.config
	patch openwrt/$(REPO)/.config <config/$(REPO)-$(PLATFORM).patch 
	patch openwrt/$(REPO)/.config <config/$(REPO)-$(PLATFORM)-$(MODEL).patch
	-rm -r openwrt/$(REPO)/files openwrt/$(REPO)/bin/$(PLATFORM)
	cp -a files/common openwrt/$(REPO)/files
	rsync -a files/$(PLATFORM)/ openwrt/$(REPO)/files/
	rsync -a files/$(PLATFORM)-$(MODEL)/ openwrt/$(REPO)/files/
	cd openwrt/$(REPO) && $(MAKE)
	mkdir -p $@
	rsync -a openwrt/$(REPO)/bin/$(PLATFORM)/ $@/
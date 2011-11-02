.NOTPARALLEL:

openwrt/backfire/.repo_access:
	mkdir -p openwrt dl
	cd openwrt && svn co svn://svn.openwrt.org/openwrt/branches/backfire
	ln -s ../../dl $(@D)/
	cd $(@D) && ./scripts/feeds update
	cd $(@D) && $(MAKE) package/symlinks
	touch $@

update/%: openwrt/%/.repo_access
	cd $< && svn update
	cd $< && ./scripts/feeds update
	cd $< && $(MAKE) package/symlinks
	touch $</.repo_access

# format config/($repo)-$(platform)-$(model).config
.SECONDEXPANSION:
config/%.config: REPO=$(shell echo $(@F) | cut -f1 -d-)
config/%.config: PLATFORM=$(shell echo $(@F) | cut -f2 -d- | cut -f1 -d.)
config/%.config: MODEL=$(shell echo $(@F) | cut -f3- -d- | cut -f1 -d.)
config/%.config: $$(shell find config -iname '$$(REPO).config') \
			     $$(shell find config -iname '$$(REPO)-$$(PLATFORM).patch') \
				 $$(shell find config -iname '$$(REPO)-$$(PLATFORM)-$$(MODEL).patch')
	cp config/$(REPO).config $@~
	if [ -n "$(MODEL)" ]; then 	\
		patch $@~ <config/$(REPO)-$(PLATFORM).patch; \
		patch $@~ <config/$(REPO)-$(PLATFORM)-$(MODEL).patch; \
	else \
		patch $@~ <config/$(REPO)-$(PLATFORM).patch; \
	fi
	mv $@~ $@

# format image/($repo)/openwrt-$(platform)-$(model)
.SECONDEXPANSION:
image/%: REPO=$(shell basename $(@D))
image/%: PLATFORM=$(shell echo $(@F) | cut -f2 -d-)
image/%: MODEL=$(shell echo $(@F) | cut -f3- -d-)
image/%: config/$$(REPO)-$$(PLATFORM)-$$(MODEL).config \
			 openwrt/$$(REPO)/.repo_access 
	@echo === Building $(REPO), $(PLATFORM), $(MODEL) ===
	cp $< openwrt/$(REPO)/.config
	-rm -r openwrt/$(REPO)/files openwrt/$(REPO)/bin/$(PLATFORM)
	cp -a files/common openwrt/$(REPO)/files
	[ -d files/$(PLATFORM) ] && rsync -a files/$(PLATFORM)/ openwrt/$(REPO)/files/
	[ -d files/$(PLATFORM)-$(MODEL) ] && rsync -a files/$(PLATFORM)-$(MODEL)/ openwrt/$(REPO)/files/
	cd openwrt/$(REPO) && $(MAKE)
	mkdir -p $@
	rsync -a openwrt/$(REPO)/bin/$(PLATFORM)/ $@/

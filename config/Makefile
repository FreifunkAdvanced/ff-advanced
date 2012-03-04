.SECONDEXPANSION:
%: REPO=$(shell echo $(@F) | cut -f1 -d-)
%: PLAT=$(shell echo $(@F) | cut -f2 -d-)
%: 
	[[ $(REPO) == $(PLAT) ]] && \
		for pla in $(PLATFORM); do \
			make $(REPO)-$${pla}.config; \
		done || make $(@F).config

.SECONDEXPANSION:
%.config: REPO=$(shell echo $(@F) | cut -f1 -d-)
%.config: PLAT=$(shell echo $(@F) | cut -f2 -d- | cut -f1 -d.)
%.config: MODEL=$(shell echo $(@F) | cut -f3- -d- | cut -f1 -d.)
%.config: $$(shell find . -iname '$$(REPO).config') \
	$$(shell find . -iname '$$(REPO)-$$(PLAT).patch') \
	$$(shell find . -iname '$$(REPO)-$$(PLAT)-$$(MODEL).patch')
	cp $(REPO).config $@~
	if [ -n "$(MODEL)" ]; then 	\
		patch -s $@~ < $(REPO)-$(PLAT).patch && \
		patch -s $@~ < $(REPO)-$(PLAT)-$(MODEL).patch; \
		echo '  PATCH   $(REPO)-$(PLAT)-$(MODEL).config'; \
	else \
		patch -s $@~ < $(REPO)-$(PLAT).patch; \
		echo '  PATCH   $(REPO)-$(PLAT).config'; \
		for com in $(COMMUNITY); do \
			make $(REPO)-$(PLAT)-$${com}.config; \
		done \
	fi
	mv $@~ $@


PHONY += mo mo-clean po pot

SELF := $(lastword $(MAKEFILE_LIST))

DOMAIN = koreader
TEMPLATE_DIR = l10n/templates
MSGFMT_BIN = msgfmt
XGETTEXT_BIN = xgettext

PO_FILES = $(wildcard l10n/*/*.po)
MO_FILES = $(PO_FILES:%.po=%.mo)

%.mo: %.po
	@$(MSGFMT_BIN) --no-hash -o $@ $<

mo:
	$(MAKE) $(if $(PARALLEL_JOBS),--jobs=$(PARALLEL_JOBS)) $(if $(PARALLEL_LOAD),--load-average=$(PARALLEL_LOAD)) --silent --file=$(SELF) $(MO_FILES)

mo-clean:
	rm -f $(MO_FILES)

pot:
	mkdir -p $(TEMPLATE_DIR)
	$(XGETTEXT_BIN) --from-code=utf-8 \
		--keyword=C_:1c,2 --keyword=N_:1,2 --keyword=NC_:1c,2,3 \
		--add-comments=@translators \
		*.lua `find api_handlers -iname "*.lua" | sort` \
		-o $(TEMPLATE_DIR)/$(DOMAIN).pot

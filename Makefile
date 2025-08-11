PHONY += pot

SELF := $(lastword $(MAKEFILE_LIST))

DOMAIN = koreader
TEMPLATE_DIR = l10n/templates
MSGFMT_BIN = msgfmt
XGETTEXT_BIN = xgettext

PO_FILES = $(wildcard l10n/*/*.po)
MO_FILES = $(PO_FILES:%.po=%.mo)

pot:
	mkdir -p $(TEMPLATE_DIR)
	$(XGETTEXT_BIN) --from-code=utf-8 \
		--keyword=C_:1c,2 --keyword=N_:1,2 --keyword=NC_:1c,2,3 \
		--add-comments=@translators \
		`find . -name "*.lua" | sort` \
		-o $(TEMPLATE_DIR)/$(DOMAIN).pot

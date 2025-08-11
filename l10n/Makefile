PHONY += pot merge

DOMAIN = koreader
TEMPLATE_DIR = templates
MSGFMT_BIN = msgfmt
MSGMERGE_BIN = msgmerge
XGETTEXT_BIN = xgettext

PO_FILES  := $(wildcard */*.po)

merge: pot
	$(MSGMERGE_BIN) --update --no-fuzzy-matching --backup=none $(PO_FILES) $(TEMPLATE_DIR)/$(DOMAIN).pot

pot:
	mkdir -p $(TEMPLATE_DIR)
	$(XGETTEXT_BIN) --from-code=utf-8 \
		--keyword=C_:1c,2 --keyword=N_:1,2 --keyword=NC_:1c,2,3 \
		--add-comments=@translators \
		`find .. -name "*.lua" | sort` \
		-o $(TEMPLATE_DIR)/$(DOMAIN).pot

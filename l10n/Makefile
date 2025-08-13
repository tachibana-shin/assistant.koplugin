PHONY += pot merge check

DOMAIN = koreader
TEMPLATE_DIR = templates
MSGFMT_BIN = msgfmt
MSGMERGE_BIN = msgmerge
MSGATTRIB_BIN = msgattrib 
MSGCAT_BIN = msgcat
XGETTEXT_BIN = xgettext

PO_FILES  := $(wildcard */*.po)
LANGS     := $(patsubst %/,%,$(filter-out templates/,$(wildcard */)))

merge: pot
	@for po_file in $(PO_FILES); do \
		$(MSGMERGE_BIN) --update --no-fuzzy-matching --backup=none $$po_file $(TEMPLATE_DIR)/$(DOMAIN).pot; \
		$(MSGATTRIB_BIN) --no-obsolete -i $$po_file -o $$po_file; \
	done

genuntranslated:
	@for po_file in $(PO_FILES); do \
		dir=$$(dirname $$po_file); \
		$(MSGATTRIB_BIN) --untranslated $$po_file -o $$dir/untranslated.po; \
	done

mergeuntranslated:
	@for po_file in $(PO_FILES); do \
		dir=$$(dirname $$po_file); \
		$(MSGCAT_BIN) --use-first $$po_file $$dir/updated_translated.po -o updated.po; \
		mv updated.po $$po_file; \
	done

check:
	@echo "Checking syntax of existing .po files..."
	@for po_file in $(PO_FILES); do \
		$(MSGFMT_BIN) --check -o /dev/null $$po_file; \
	done

clean:
	@echo "Cleaning intermediate translation files..."
	@find . -type f \( -name "untranslated.po" -o -name "updated_translated.po" -o -name "updated.po" -o -name "updatedd.po" \) -print -delete

ai:
	@for LANG in $(LANGS); do \
		./AI_TRANSLATE.sh $$LANG; sleep 10; \
	done

pot:
	mkdir -p $(TEMPLATE_DIR)
	$(XGETTEXT_BIN) --from-code=utf-8 \
		--keyword=C_:1c,2 --keyword=N_:1,2 --keyword=NC_:1c,2,3 \
		--add-comments=@translators \
		`find .. -name "*.lua" | sort` \
		-o $(TEMPLATE_DIR)/$(DOMAIN).pot

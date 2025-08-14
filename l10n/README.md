# Multi-language support

The plugin use the same language tranlate logic with KOReader.

## How it Works

Translate: `template/koreader.pot` -> `LANG/koreader.po`

## Contribute your language

1. Determine the abbreviation code of your language based on the language list.  As `LANG_CODE`.
2. Create a dir under this `l10n`, `mkdir LANG_CODE`
3. copy `template/koreader.pot` to `LANG_CODE/koreader.po`
4. Translate `LANG_CODE/koreader.po`

## Updates

When source changes, run `make` under this dir.

`template/koreader.pot` will be regenerated, and other language translations will merge the result with the new template.

#### Use AI

Use the following prompt to translate your language, attach `template/koreader.pot` 

```
Translate the following gettext .po file content to __YOUR_LANGUAGE__.
Preserve the .po file structure, including msgid, msgstr, and other metadata.
Ensure accurate and context-aware translation.
The message will display on UI, keep the translation clean and short and easy understanding.
The first message is the metadata for the PO file. Make the necessary updates to the metadata.
The project is named `assitant.koplugin`.  Fill the Project-Id-Version attribute.
Fill in the `Language` attribute with current translating language and the language code.
Fill in the `Language-Team` and `Last-Translator` with your model name and versions.
Do not modify other file structure.
Only output the translated file content, do not use markdown format.
```

Save the generated file content to `LANG_CODE/koreader.ko`

Most translation files in the directory are generated with a script `AI_TRANSLATE.sh` with an API, which automates the above process.

## Language abbr TABLE

```lua
    language_names = {
        en = "English",
        en_GB = "English (United Kingdom)",
        ca = "Catalá",
        cs = "Čeština",
        da = "Dansk",
        de = "Deutsch",
        eo = "Esperanto",
        es = "Español",
        eu = "Euskara",
        fi = "Suomi",
        fr = "Français",
        gl = "Galego",
        it_IT = "Italiano",
        he = "עִבְרִית",
        hr = "Hrvatski",
        hu = "Magyar",
        lt_LT = "Lietuvių",
        lv = "Latviešu",
        nl_NL = "Nederlands",
        nb_NO = "Norsk bokmål",
        pl = "Polski",
        pl_PL = "Polski2",
        pt_PT = "Português",
        pt_BR = "Português do Brasil",
        ro = "Română",
        ro_MD = "Română (Moldova)",
        sk = "Slovenčina",
        sv = "Svenska",
        th = "ภาษาไทย",
        vi = "Tiếng Việt",
        tr = "Türkçe",
        vi_VN = "Viet Nam",
        ar = "عربى",
        bg_BG = "български",
        bn = "বাংলা",
        el = "Ελληνικά",
        fa = "فارسی",
        hi = "हिन्दी",
        ja = "日本語",
        ka = "ქართული",
        kk = "Қазақ",
        ko_KR = "한국어",
        ru = "Русский",
        sr = "Српски",
        uk = "Українська",
        zh = "中文",
        zh_CN = "简体中文",
        zh_TW = "中文（台灣)",
    }
```
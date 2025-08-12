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
Translate the following gettext .po file content to {{YOUR LANGUAGE}}.  Preserve the .po file structure, including msgid, msgstr, and other metadata.  Ensure accurate and context-aware translation. Do not modify the file structure.  Here is the file content:
```

Save the generated file content to `LANG_CODE/koreader.ko`


## Language abbr TABLE

```lua
    language_names = {
        C = "English",
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
        ["zh_TW.Big5"] = "中文（台灣）（Big5）",
    }
```
#!/bin/bash
# translate_po.sh
# Purpose: Translate KOReader *.po files with ChatGPT

set -euo pipefail

# -------------------- Configuration --------------------
TEMPLATE_FILE="templates/koreader.pot"
API_ENDPOINT=${API_ENDPOINT:-"https://api.openai.com/v1/chat/completions"}
API_MODEL=${API_MODEL:-"gpt-4o-mini"}
AUTH_HEADER="Authorization: Bearer ${API_KEY}"
PROMPT_TEMPLATE="Translate the following gettext .po file content to __YOUR_LANGUAGE__. \
Preserve the .po file structure, including msgid, msgstr, and other metadata. \
Ensure accurate and context-aware translation. \
The first message is a po tranlation file metadata message. \
Fill in the \`Language\` attribute with current translating language. \
Fill in the \`Language-Team\` with AI Generated info including your model name and versions. \
Do not modify other file structure. \
Only output the translated file content, do not use markdown format. \
"

declare -A LANG_MAP=(
  ["en"]="English"
  ["en_GB"]="English (United Kingdom)"
  ["ca"]="Catalá"
  ["cs"]="Čeština"
  ["da"]="Dansk"
  ["de"]="Deutsch"
  ["eo"]="Esperanto"
  ["es"]="Español"
  ["eu"]="Euskara"
  ["fi"]="Suomi"
  ["fr"]="Français"
  ["gl"]="Galego"
  ["it_IT"]="Italiano"
  ["he"]="עִבְרִית"
  ["hr"]="Hrvatski"
  ["hu"]="Magyar"
  ["lt_LT"]="Lietuvių"
  ["lv"]="Latviešu"
  ["nl_NL"]="Nederlands"
  ["nb_NO"]="Norsk bokmål"
  ["pl"]="Polski"
  ["pl_PL"]="Polski2"
  ["pt_PT"]="Português"
  ["pt_BR"]="Português do Brasil"
  ["ro"]="Română"
  ["ro_MD"]="Română (Moldova)"
  ["sk"]="Slovenčina"
  ["sv"]="Svenska"
  ["th"]="ภาษาไทย"
  ["vi"]="Tiếng Việt"
  ["tr"]="Türkçe"
  ["vi_VN"]="Viet Nam"
  ["ar"]="عربى"
  ["bg_BG"]="български"
  ["bn"]="বাংলা"
  ["el"]="Ελληνικά"
  ["fa"]="فارسی"
  ["hi"]="हिन्दी"
  ["ja"]="日本語"
  ["ka"]="ქართული"
  ["kk"]="Қазақ"
  ["ko_KR"]="한국어"
  ["ru"]="Русский"
  ["sr"]="Српски"
  ["uk"]="Українська"
  ["zh"]="中文"
  ["zh_CN"]="简体中文"
  ["zh_TW"]="中文（台灣)"
)

# -------------------- Validation --------------------
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <LANGUAGE_CODE>" >&2
  exit 1
fi

LANG_CODE="$1"

[[ -v LANG_MAP["$LANG_CODE"] ]] || {
  echo "Error: Language code '$LANG_CODE' not supported." >&2
  exit 1
}

[[ -f "$TEMPLATE_FILE" ]] || {
  echo "Error: Template file '$TEMPLATE_FILE' not found." >&2
  exit 1
}

[[ -v OPENAI_API_KEY ]] || {
  echo "Error: OPENAI_API_KEY environment variable not set." >&2
  exit 1
}

LANG_FULLNAME="${LANG_MAP["$LANG_CODE"]}"
PROMPT="${PROMPT_TEMPLATE//__YOUR_LANGUAGE__/$LANG_FULLNAME}"
# -------------------- Create directory --------------------
mkdir -p "$LANG_CODE"

# -------------------- Build payload for API request --------------------
PAYLOAD=$(jq -n \
  --arg model "${API_MODEL}" \
  --arg content "$PROMPT" \
  --rawfile file_content "$TEMPLATE_FILE" \
  '{
     model: $model,
     messages: [
       {role: "system", content: $content},
       {role: "user",    content: $file_content}
     ],
     temperature: 0
   }')

# -------------------- Request translation --------------------
RESPONSE=$(curl -sSf -X POST "$API_ENDPOINT" \
  -H "$AUTH_HEADER" -H "Content-Type: application/json" \
  --data-raw "$PAYLOAD")

# -------------------- Extract and save result --------------------
echo "$RESPONSE" | jq -r '.choices[0].message.content' \
  > "$LANG_CODE/koreader.po"

echo "Translation completed for $LANG_CODE ($LANG_FULLNAME)."

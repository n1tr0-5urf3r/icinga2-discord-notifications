EMBED_FIELDS=("name1" "val1" "name2" "val2")

vars=(${EMBED_FIELDS[@]})
len=${#EMBED_FIELDS[@]}

WEBHOOK_DATA='{
  "username": "x",
  "avatar_url": "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
  "embeds": [ {
  "color": '$COLOR',
    "author": {
      "name": "'"Icinga Monitoring"'"
    },
    "title": "'"$SUBJECT"'",
    "description": "'"$HOSTOUTPUT"'",
    "fields": [
'

for ((i = 0; i < len; i += 2)); do
    WEBHOOK_DATA="$WEBHOOK_DATA $(printf "{")"
    WEBHOOK_DATA="$WEBHOOK_DATA $(printf "\"name\": \"${vars[i]}\"")"
    WEBHOOK_DATA="$WEBHOOK_DATA $(printf ", ")"
    WEBHOOK_DATA="$WEBHOOK_DATA $(printf "\"value\": \"${vars[i + 1]}\"")"
    WEBHOOK_DATA="$WEBHOOK_DATA $(printf "}")"
    if [ $i -lt $((len - 2)) ]; then
        WEBHOOK_DATA="$WEBHOOK_DATA $(printf ", ")"
    fi
done

WEBHOOK_DATA="$WEBHOOK_DATA $(printf "    ]
  } ]
}")"

echo $WEBHOOK_DATA

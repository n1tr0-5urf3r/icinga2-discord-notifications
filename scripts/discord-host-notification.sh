#!/bin/bash

CURLBIN="curl"
MARKDOWN_PARSER="pandoc"
IFS=""

if [ -z "`which $CURLBIN`" ] ; then
  echo "$CURLBIN not found."
  exit 1
fi


## Function helpers
Usage() {
cat << EOF

Required parameters:
  -d LONGDATETIME (\$icinga.long_date_time\$)
  -l HOSTNAME (\$host.name\$)
  -n HOSTDISPLAYNAME (\$host.display_name\$)
  -o HOSTOUTPUT (\$host.output\$)
  -r USEREMAIL (\$user.email\$)
  -s HOSTSTATE (\$host.state\$)
  -t NOTIFICATIONTYPE (\$notification.type\$)

Optional parameters:
  -4 HOSTADDRESS (\$address\$)
  -6 HOSTADDRESS6 (\$address6\$)
  -b NOTIFICATIONAUTHORNAME (\$notification.author\$)
  -c NOTIFICATIONCOMMENT (\$notification.comment\$)
  -i ICINGAWEB2URL (\$notification_icingaweb2url\$, Default: unset)
  -f MAILFROM (\$notification_mailfrom\$, requires GNU mailutils (Debian/Ubuntu) or mailx (RHEL/SUSE))
  -v (\$notification_sendtosyslog\$, Default: false)
  -x (\$notification.notes\$)

EOF
}

Help() {
  Usage;
  exit 0;
}

Error() {
  if [ "$1" ]; then
    echo $1
  fi
  Usage;
  exit 1;
}

## Main
while getopts 4:6::b:c:d:f:hi:l:n:o:r:s:t:v:x: opt
do
  case "$opt" in
    4) HOSTADDRESS=$OPTARG ;;
    6) HOSTADDRESS6=$OPTARG ;;
    b) NOTIFICATIONAUTHORNAME=$OPTARG ;;
    c) NOTIFICATIONCOMMENT=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;; # required
    f) MAILFROM=$OPTARG ;;
    h) Help ;;
    i) ICINGAWEB2URL=$OPTARG ;;
    l) HOSTNAME=$OPTARG ;; # required
    n) HOSTDISPLAYNAME=$OPTARG ;; # required
    o) HOSTOUTPUT=$OPTARG ;; # required
    r) USEREMAIL=$OPTARG ;; # required
    s) HOSTSTATE=$OPTARG ;; # required
    t) NOTIFICATIONTYPE=$OPTARG ;; # required
    v) VERBOSE=$OPTARG ;;
    x) NOTES=$OPTARG ;;
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Error ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Error ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Error ;;
  esac
done

shift $((OPTIND - 1))

## Keep formatting in sync with mail-service-notification.sh
for P in LONGDATETIME HOSTNAME HOSTDISPLAYNAME HOSTOUTPUT HOSTSTATE USEREMAIL NOTIFICATIONTYPE ; do
        eval "PAR=\$${P}"

        if [ ! "$PAR" ] ; then
                Error "Required parameter '$P' is missing."
        fi
done

case $HOSTSTATE in

  "UP")
    COLOR="25600"
    CHARACTER="(&#10004;)"
    SUBJECT_CHAR="=?UTF-8?B?4pyU?="
    ;;

  "DOWN")
    COLOR="9109504"
    CHARACTER="(&#10008;)"
    SUBJECT_CHAR="=?UTF-8?B?4pyY?="
    ;;

  "UNKNOWN")
    COLOR="8388736"
    CHARACTER="(&#63;)"
    SUBJECT_CHAR=" ? "
    ;;

  *)
    COLOR="13882323"
    ;;
esac

## Build the message's subject
SUBJECT="[$NOTIFICATIONTYPE Notification] Host $HOSTDISPLAYNAME - $HOSTSTATE"

EMBED_FIELDS=();

EMBED_FIELDS+=("$HOSTNAME" "($HOSTADDRESS)")

EMBED_FIELDS+=("Notification Date" "$LONGDATETIME")


if [ -n "$NOTIFICATIONCOMMENT" ] ; then
    EMBED_FIELDS+=("Comment" ""$NOTIFICATIONCOMMENT"/"$NOTIFICATIONAUTHORNAME"")
fi


if [ -n "$ICINGAWEB2URL" ] ; then
        URL=""${ICINGAWEB2URL}"/monitoring/host/show?host="$HOSTNAME""
        EMBED_FIELDS+=("Icinga Link" "$URL")
fi



if [  -n "$NOTES" -a ! -z "`which $MARKDOWN_PARSER`" ]
then
        NOTES_HTML=`echo "$NOTES" | $MARKDOWN_PARSER`
        EMBED_FIELDS+=("Notes" "$NOTES_HTML")
fi

vars=(${EMBED_FIELDS[@]})
len=${#EMBED_FIELDS[@]}

WEBHOOK_DATA='{
  "username": "",
  "avatar_url": "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
  "embeds": [ {
  "color": '$COLOR',
    "author": {
      "name": "'"Icinga Monitoring"'"
    },
    "title": "'"$SUBJECT"'",
    "thumbnail": {
        "url": "https://me.ihlecloud.de/img/logo.png"
    },
    "footer": {
        "text": "icinga2-discord-notification by N1tR0#0914",
        "icon_url": "https://me.ihlecloud.de/img/logo.png"
    },
    "description": "'"$HOSTOUTPUT"'",
    "fields": [
'

for ((i = 0; i < len; i += 2)); do
    WEBHOOK_DATA=""$WEBHOOK_DATA" $(printf "{")"
    WEBHOOK_DATA=""$WEBHOOK_DATA" $(printf "\"name\": \""${vars[i]}"\"")"
    WEBHOOK_DATA=""$WEBHOOK_DATA" $(printf ", ")"
    WEBHOOK_DATA=""$WEBHOOK_DATA" $(printf "\"value\": \""${vars[i + 1]}"\"")"
    WEBHOOK_DATA=""$WEBHOOK_DATA" $(printf "}")"
    if [ $i -lt $((len - 2)) ]; then
        WEBHOOK_DATA=""$WEBHOOK_DATA" $(printf ", ")"
    fi
done

WEBHOOK_DATA=""$WEBHOOK_DATA" $(printf "    ]
  } ]
}")"

WEBHOOK_URL=""

curl --fail --progress-bar -H Content-Type:application/json -d "$WEBHOOK_DATA" "$WEBHOOK_URL"
EXIT_CODE=$?
if [ ${EXIT_CODE} != 0 ]; then
  echo "[Webhook]: Unable to send webhook."
else
  echo "[Webhook]: Successfully sent the webhook."
fi
exit $EXIT_CODE
#!/bin/bash
###############################################################################
# Written by Fabian Ihle, fabi@ihlecloud.de                                   #
# Created: 19.10.2021                                                         #
# github: https://github.com/n1tr0-5urf3r/icinga2-discord-notifications       #
#                                                                             #
# Scripts to setup icinga2                                                    #
# notifications with a discord webhook                                        #
# -------------------------------------------------------------               #
# Changelog:                                                                  #
# 191021 Version .1 - Created                                                 #
# 201021 Version .2 - Added contact support                                   #
# 291021 Version .3 - Fix bug with newlines in service output                 #
# 291106 Version .3.1 - Fix variable expansion in service notification        #
###############################################################################

CURLBIN="curl"
MARKDOWN_PARSER="pandoc"
IFS=""

# Fill in those
THUMBNAIL_URL=""

if [ -z "`which $CURLBIN`" ] ; then
  echo "$CURLBIN not found."
  exit 1
fi

## Function helpers
Usage() {
cat << EOF

Required parameters:
  -d LONGDATETIME (\$icinga.long_date_time\$)
  -e SERVICENAME (\$service.name\$)
  -l HOSTNAME (\$host.name\$)
  -n HOSTDISPLAYNAME (\$host.display_name\$)
  -o SERVICEOUTPUT (\$service.output\$)
  -r Webhook URL (\$user.vars.webhook_url\$)
  -s SERVICESTATE (\$service.state\$)
  -t NOTIFICATIONTYPE (\$notification.type\$)
  -u SERVICEDISPLAYNAME (\$service.display_name\$)

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
while getopts 4:6:b:c:d:e:f:hi:l:n:o:r:s:t:u:v:x: opt
do
  case "$opt" in
    4) HOSTADDRESS=$OPTARG ;;
    6) HOSTADDRESS6=$OPTARG ;;
    b) NOTIFICATIONAUTHORNAME=$OPTARG ;;
    c) NOTIFICATIONCOMMENT=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;; # required
    e) SERVICENAME=$OPTARG ;; # required
    f) MAILFROM=$OPTARG ;;
    h) Usage ;;
    i) ICINGAWEB2URL=$OPTARG ;;
    l) HOSTNAME=$OPTARG ;; # required
    n) HOSTDISPLAYNAME=$OPTARG ;; # required
    o) SERVICEOUTPUT=$OPTARG ;; # required
    r) WEBHOOK_URL=$OPTARG ;; # required
    s) SERVICESTATE=$OPTARG ;; # required
    t) NOTIFICATIONTYPE=$OPTARG ;; # required
    u) SERVICEDISPLAYNAME=$OPTARG ;; # required
    v) VERBOSE=$OPTARG ;;
    x) NOTES=$OPTARG ;;
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Usage ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Usage ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Usage ;;
  esac
done

shift $((OPTIND - 1))

## Check required parameters (TODO: better error message)
## Keep formatting in sync with mail-host-notification.sh
if [ ! "$LONGDATETIME" ] \
|| [ ! "$HOSTNAME" ] || [ ! "$HOSTDISPLAYNAME" ] \
|| [ ! "$SERVICENAME" ] || [ ! "$SERVICEDISPLAYNAME" ] \
|| [ ! "$SERVICEOUTPUT" ] || [ ! "$SERVICESTATE" ] \
|| [ ! "$WEBHOOK_URL" ] || [ ! "$NOTIFICATIONTYPE" ]; then
  Error "Requirement parameters are missing."
fi


case $SERVICESTATE in

  "OK")
    COLOR="25600"
    ;;

  "WARNING")
    COLOR="12150016"
    ;;

  "CRITICAL")
    COLOR="9109504"
    ;;

  "UNKNOWN")
    COLOR="8388736"
    ;;
  *)
    COLOR="13882323"
    ;;
esac

# Replace newlines from service output as this breaks the embed payload
SERVICEOUTPUT=$(echo "${SERVICEOUTPUT}" | sed ':a;N;$!ba;s/\n/, /g')

## Build the message's subject
SUBJECT="[$NOTIFICATIONTYPE Notification] $SERVICESTATE - ($HOSTDISPLAYNAME - $SERVICEDISPLAYNAME)"

EMBED_FIELDS=();

if [ -n "$HOSTADDRESS" ] ; then
  # TODO: add IPv6 support
  EMBED_FIELDS+=("$HOSTNAME" "$HOSTADDRESS")
fi

EMBED_FIELDS+=("Notification Date" "$LONGDATETIME")

if [ -n "$NOTIFICATIONCOMMENT" ] ; then
    EMBED_FIELDS+=("Comment" ""$NOTIFICATIONCOMMENT"/"$NOTIFICATIONAUTHORNAME"")
fi


if [ -n "$ICINGAWEB2URL" ] ; then
        URL="$ICINGAWEB2URL/monitoring/service/show?host=$HOSTNAME&service=$SERVICENAME"
        EMBED_FIELDS+=("Icinga Link" "$URL")
fi


if [  -n "$NOTES" -a ! -z "`which $MARKDOWN_PARSER`" ] ; then
        NOTES_HTML=`echo "$NOTES" | $MARKDOWN_PARSER`
        EMBED_FIELDS+=("Notes" "$NOTES_HTML")
fi

vars=(${EMBED_FIELDS[@]})
len=${#EMBED_FIELDS[@]}


WEBHOOK_DATA='{
  "username": "",
  "avatar_url": "https://exchange.icinga.com//img/fav/cropped-icinga-favicon-512x512px-192x192.png",
  "embeds": [ {
  "color": '$COLOR',
    "author": {
      "name": "'"Icinga Monitoring"'"
    },
    "title": "'"$SUBJECT"'",
    "thumbnail": {
        "url": "'"$THUMBNAIL_URL"'"
    },
    "footer": {
        "text": "icinga2-discord-notification by N1tR0#0914",
        "icon_url": "https://me.ihlecloud.de/img/logo.png"
    },
    "description": "'"$SERVICEOUTPUT"'",
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

curl --fail -H Content-Type:application/json -d "$WEBHOOK_DATA" "$WEBHOOK_URL"
EXIT_CODE=$?
if [ ${EXIT_CODE} != 0 ]; then
  echo "[Webhook]: Unable to send webhook."
else
  echo "[Webhook]: Successfully sent the webhook."
fi
exit $EXIT_CODE
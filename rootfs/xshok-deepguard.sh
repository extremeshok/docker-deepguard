#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
#
# Notes:
# Script must be placed into the same directory as the docker-compose.yml
#
# Assumptions: Docker and Docker-compose Installed
#
# Tested on KVM, VirtualBox and Dedicated Server
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#
################################################################################

IGNORE_LIST="${IGNORE_LIST:-person, bicycle, car, motorcycle, airplane, bus, train, truck, boat, trafficlight, firehydrant, stop_sign, parkingmeter, bench, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe, backpack, umbrella, handbag, tie, suitcase, frisbee, skis, snowboard, sportsball, kite, baseballbat, baseballglove, skateboard, surfboard, tennisracket, bottle, wineglass, cup, fork, knife, spoon, bowl, banana, apple, sandwich, orange, broccoli, carrot, hotdog, pizza, donot, cake, chair, couch, pottedplant, bed, diningtable, toilet, tv, laptop, mouse, remote, keyboard, cellphone, microwave, oven, toaster, sink, refrigerator, book, clock, vase, scissors, teddybear, hairdryer, toothbrush}"

NOTIFY_LIST="${NOTIFY_LIST:-person, cat}"

VALID_IMAGE_EXTENSION_LIST="${VALID_IMAGE_EXTENSION_LIST:-png, jpg, jpeg, gif, bmp}"
#requires graphicsmagick

#CAMERA_NAME_DELIMINATOR="${CAMERA_NAME_DELIMINATOR:-_}"
CAMERA_NAME_DELIMINATOR="${CAMERA_NAME_DELIMINATOR:-.}"

DIR_INPUT="${DIR_INPUT:-/data/input}"
DIR_OUTPUT="${DIR_OUTPUT:-/data/output}"
DIR_BACKUP="${DIR_BACKUP:-/data/backup}"

BACKUP_ORIGINAL="${BACKUP_ORIGINAL:-yes}"
SAVE_OUTPUT="${SAVE_OUTPUT:-yes}"
EMPTY_INPUT_DIR_ON_START="${EMPTY_INPUT_DIR_ON_START:-no}"
DRAW_RESULTS="${DRAW_RESULTS:-yes}"

DEBUG="${DEBUG:-yes}"
BE_VERBOSE="${BE_VERBOSE:-yes}"

ALERT_MAX_ALERTS="${ALERT_MAX_ALERTS:-2}"
ALERT_PERIOD_SECONDS="${ALERT_PERIOD_SECONDS:-120}"

DEEPSTACK_URL="${DEEPSTACK_URL:-http://deepstack:5000}"
DEEPSTACK_BACKUP_URL="${DEEPSTACK_BACKUP_URL:-http://deepstackbak:5000}"
DEEPSTACK_CONFIDENCE_LIMIT="${DEEPSTACK_CONFIDENCE_LIMIT:-5}"

#NOTIFY
NOTIFY_ZONEMINDER="${NOTIFY_ZONEMINDER:-no}"
ZONEMINDER_NOFITY_HOST="${ZONEMINDER_NOFITY_HOST:-zoneminder}"
ZONEMINDER_NOFITY_PORT="${ZONEMINDER_NOFITY_PORT:-6802}"

NOTIFY_URL="${NOTIFY_URL:-no}"
URL_NOTIFY="${URL_NOTIFY:-http://blueiris/admin?trigger&camera=hd%%CAMERA%%&user=ai&pw=ai}"

#ALERT
ALERT_PUSHOVER="${ALERT_PUSHOVER:-no}"
PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-}"
PUSHOVER_KEY="${PUSHOVER_KEY:-}"
PUSHOVER_PRIORITY="${PUSHOVER_PRIORITY:-2}" #2=emergency
PUSHOVER_EXPIRE="${PUSHOVER_EXPIRE:-600}"
PUSHOVER_RETRY="${PUSHOVER_RETRY:-30}"
PUSHOVER_DEVICE="${PUSHOVER_DEVICE:-}"
PUSHOVER_SOUND="${PUSHOVER_SOUND:-siren}"

ALERT_TELEGRAM="${ALERT_TELEGRAM:-no}"
TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

ALERT_WHATSMATE="${ALERT_WHATSMATE:-no}"
WHATSMATE_CLIENT_ID="${WHATSMATE_CLIENT_ID:-}"
WHATSMATE_CLIENT_SECRET="${WHATSMATE_CLIENT_SECRET:-}"
WHATSMATE_WHATSAPP_NUMBER="${WHATSMATE_WHATSAPP_NUMBER:-}"

ALERT_NEXMO="${ALERT_NEXMO:-no}"
NEXMO_API_KEY="${NEXMO_API_KEY:-}"
NEXMO_API_SECRET="${NEXMO_API_SECRET:-}"
NEXMO_SMS_TO_NUMBER="${NEXMO_SMS_TO_NUMBER:-}"
NEXMO_SMS_FROM="${NEXMO_SMS_FROM:-}"

ALERT_TWILIO="${ALERT_TWILIO:-no}"
TWILIO_ACCOUNT_SID="${TWILIO_ACCOUNT_SID:-}"
TWILIO_AUTH_TOKEN="${TWILIO_AUTH_TOKEN:-}"
TWILIO_SMS_TO_NUMBER="${TWILIO_SMS_TO_NUMBER:-}"
TWILIO_SMS_FROM="${TWILIO_SMS_FROM:-}"

WATERMARK="${WATERMARK:-DeepGuard.co.za}"

# PROGRAM SETTINGS
CURL_OPTIONS="--retry 2 --retry-connrefused 2 --retry-max-time 10 --retry-delay 1 --insecure --show-error"
# ls /usr/share/fonts/gsfonts/
FONT="/usr/share/fonts/gsfonts/NimbusSansNarrow-Regular.otf"
#FONT="/usr/share/fonts/gsfonts/NimbusMonoPS-Regular.otf"
#FONT="/usr/share/fonts/gsfonts/NimbusRoman-Regular.otf"

###################
#### FUNCTIONS ####
###################
function notify_url { #cameraname
  test "$BE_VERBOSE" == "1" && echo "Notify: url"
  if [ "$URL_NOTIFY" != "" ] && [[ "${URL_NOTIFY,,}" == "http"* ]] ; then
    result="$(curl $CURL_OPTIONS -s "${URL_NOTIFY/\%\%CAMERA\%\%/$1}"  2>&1)"
    test "$DEBUG" == "1" && echo "url @ ${cameraname}: ${result}"
  else
    echo "ERROR: URL_NOTIFY is empty or missing http/https"
  fi
}

function notify_zoneminder { #cameraname
  test "$BE_VERBOSE" == "1" && echo "Notify: zoneminder"
  if [ "$ZONEMINDER_NOFITY_HOST" != "" ] && [[ $ZONEMINDER_NOFITY_PORT =~ ^-?[0-9]+$ ]] ; then
    result="$(echo "${BLUEIRIS_URL_NOTIFY/\%\%CAMERA\%\%/$1}|on+10|255|test|test" | nc $ZONEMINDER_NOFITY_HOST $ZONEMINDER_NOFITY_PORT  2>&1)"
    test "$DEBUG" == "1" && echo "zoneminder @ ${cameraname}: ${result}"
  else
    echo "ERROR: ZONEMINDER_NOFITY_HOST is empty or ZONEMINDER_NOFITY_PORT is not a number"
  fi
}

function alert_pushover { #message #image
  test "$BE_VERBOSE" == "1" && echo "Alert: pushover"
  if [ "$PUSHOVER_TOKEN" != "" ] && [ "$PUSHOVER_KEY" != "" ] ; then
    result="$(curl $CURL_OPTIONS -F "token=${PUSHOVER_TOKEN}" -F "user=${PUSHOVER_KEY}" -F "attachment=@${2}" -form-string "title=${1/ *}" --form-string "sound=${PUSHOVER_SOUND}" ${PUSHOVER_DEVICE:+ --form-string "device=${PUSHOVER_DEVICE}"} ${PUSHOVER_PRIORITY:+ --form-string "priority=${PUSHOVER_PRIORITY}"} ${PUSHOVER_EXPIRE:+ --form-string "expire=${PUSHOVER_EXPIRE}"} ${PUSHOVER_RETRY:+ --form-string "retry=${PUSHOVER_RETRY}"} -F "message=$1" https://api.pushover.net/1/messages.json  2>&1)"
    test "$DEBUG" == "1" && echo "pushover: $result"
  else
    echo "ERROR: PUSHOVER_TOKEN or PUSHOVER_KEY is empty"
  fi
}

function alert_telegram { #message #image
  test "$BE_VERBOSE" == "1" && echo "Alert: telegram"
  if [ "$TELEGRAM_CHAT_ID" != "" ] && [ "$TELEGRAM_TOKEN" != "" ] ; then
    result="$(curl $CURL_OPTIONS -F "chat_id=${TELEGRAM_CHAT_ID}" -F "text=$1" https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage 2>&1)"
    test "$DEBUG" == "1" && echo "$result"
    result="$(curl $CURL_OPTIONS -F "chat_id=${TELEGRAM_CHAT_ID}" -F "photo=@${2}" https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendPhoto 2>&1)"
    test "$DEBUG" == "1" && echo "telegram: $result"
  else
    echo "ERROR: TELEGRAM_CHAT_ID or TELEGRAM_TOKEN is empty"
  fi
}

#https://whatsmate.github.io/2017-10-25-send-whatsapp-image-group-bash-shell-script/
function alert_whatsmate { #message #image
  test "$BE_VERBOSE" == "1" && echo "Alert: whatsmate"
  if [ "$WHATSMATE_CLIENT_ID" != "" ] && [ "$WHATSMATE_CLIENT_SECRET" != "" ] && [ "$WHATSMATE_WHATSAPP_NUMBER" != "" ] ; then
    random="$(date '+%s')"
    cat > "/tmp/jsonbody_${random}" << _EOM_
  {
    "number": "$WHATSMATE_WHATSAPP_NUMBER",
    "caption": "${1}",
    "image": "$(base64 -w 0 ${2})"
  }
_EOM_
    result="$(curl $CURL_OPTIONS -X "POST" -H "X-WM-CLIENT-ID: ${WHATSMATE_CLIENT_ID}" -H "X-WM-CLIENT-SECRET: ${WHATSMATE_CLIENT_SECRET}" -H "Content-Type: application/json" --data-binary @"/tmp/jsonbody_${random}"  http://api.whatsmate.net/v3/whatsapp/group/image/message/${WHATSMATE_WHATSAPP_NUMBER0o}  2>&1)"
    test "$DEBUG" == "1" && echo "whatsmate: $result"
    rm -f "/tmp/jsonbody_${random}"
  else
    echo "ERROR: WHATSMATE_CLIENT_ID or WHATSMATE_CLIENT_SECRET or WHATSMATE_WHATSAPP_NUMBER is empty"
  fi
}

function alert_nexmo { #message
  test "$BE_VERBOSE" == "1" && echo "Alert: nexmo"
  if [ "$NEXMO_SMS_FROM" != "" ] && [ "$NEXMO_SMS_TO_NUMBER" != "" ] && [ "$NEXMO_API_KEY" != "" ] && [ "$NEXMO_API_SECRET" != "" ] ; then
    result="$(curl $CURL_OPTIONS -X "POST" "https://rest.nexmo.com/sms/json" -d "from=+${NEXMO_SMS_FROM/\+}" -d "text=${1:0:160}" -d "to=+${NEXMO_SMS_TO_NUMBER/\+}" -d "api_key=${NEXMO_API_KEY}" -d "api_secret=${NEXMO_API_SECRET}"  2>&1)"
    test "$DEBUG" == "1" && echo "nexmo: $result"
  else
    echo "ERROR: NEXMO_SMS_FROM or NEXMO_SMS_TO_NUMBER or NEXMO_API_KEY or NEXMO_API_SECRET is empty"
  fi
}

function alert_twilio { #message
  test "$BE_VERBOSE" == "1" && echo "Alert: twilio"
  if [ "$TWILIO_ACCOUNT_SID" != "" ] && [ "$TWILIO_AUTH_TOKEN" != "" ] && [ "$TWILIO_SMS_TO_NUMBER" != "" ] && [ "$TWILIO_SMS_TO_NUMBER" != "" ] ; then
    result="$(curl $CURL_OPTIONS -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}" -d "From=+${TWILIO_SMS_FROM/\+}" -d "To=+${TWILIO_SMS_TO_NUMBER/\+}" -d "Body=${1:0:160}" "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/SMS/Messages" 2>&1)"
    test "$DEBUG" == "1" && echo "twilio: $result"
  else
    echo "ERROR: TWILIO_ACCOUNT_SID or TWILIO_AUTH_TOKEN or TWILIO_SMS_FROM or TWILIO_SMS_TO_NUMBER is empty"
  fi
}

function process_image { #image_in #image_out
  export RUN_COUNT=$((RUN_COUNT+1))

  image_in="$1"
  image_out="$2"

  if [ -f "$image_in" ] ; then
    test "$BE_VERBOSE" == "1" && echo "Processing image: $image_in"
    #result="$(curl --retry 1 --retry-connrefused 1 --retry-max-time 30 --retry-delay 1 --fail-early --insecure --silent -X "POST" -F "image=@${image_in}" "${DEEPSTACK_URL}/v1/vision/detection")"
    result="$(curl -k -X POST -F image=@"${image_in}" "${DEEPSTACK_URL}/v1/vision/detection")"
    res=$?
    if [ "$res" != 0 ] ; then
      test "$BE_VERBOSE" == "1" && echo "Retrying with deepstack backup"
      #result="$(curl --retry 1 --retry-connrefused 1 --retry-max-time 30 --retry-delay 1 --fail-early --insecure --silent -X "POST" -F "image=@${image_in}" "${DEEPSTACK_BACKUP_URL}/v1/vision/detection")"
      result="$(curl -k -X POST -F image=@"${image_in}" "${DEEPSTACK_BACKUP_URL}/v1/vision/detection")"
      res=$?
    fi
    if [ "$res" == 0 ] ; then
      test "$DEBUG" == "1" && echo "$result"

      count=0
      while read "confidence" "label" "y_min" "x_min" "y_max" "x_max"; do
        if [ ! -z "$confidence" ] ; then
          confidence="${confidence:2:2}"
        else
          confidence=0
        fi
        test "$DEBUG" == "1" && echo "$confidence | $label | $y_min | $x_min | $y_max | $x_max"
        SUB=("$confidence" "$label" "$y_min" "$x_min" "$y_max" "$x_max")
        MAIN_ARRAY[$count]="${SUB[*]}"
        count=$((count + 1))
      done < <(echo "$result" | sed -e 's/[[:space:]]//g' | jq -r '.predictions[]|"\(.confidence) \(.label) \(.y_min) \(.x_min) \(.y_max) \(.x_max)"')

      test "$DEBUG" == "1" && echo "count : ${#MAIN_ARRAY[@]}"

      COUNT=${#MAIN_ARRAY[@]}

      declare -A COUNTER

      result_boxes=""

      for ((i=0; i<$COUNT; i++)) ; do
        SUB=(${MAIN_ARRAY[i]})
        #assign
        confidence="${SUB[0]}"
        label="${SUB[1]}"
        y_min="${SUB[2]}"
        x_min="${SUB[3]}"
        y_max="${SUB[4]}"
        x_max="${SUB[5]}"

        #shellcheck disable=SC2076
        if [[ "$confidence" -ge "$DEEPSTACK_CONFIDENCE_LIMIT" ]] ; then

          if [[ "$NOTIFY_LIST" =~ ",${label,,}," ]] || [[ ! "$IGNORE_LIST" =~ ",${label,,}," ]] ; then
            color="$(echo "$label" | md5sum)"
            color="${color:2:6}"

            test "$DEBUG" == "1" && echo "$confidence | $label | $y_min | $x_min | $y_max | $x_max"

            result_boxes="${result_boxes} -stroke \"#${color}\" -fill none -draw \"rectangle ${x_min},${y_min},${x_max},${y_max}\" -stroke none -fill \"#${color}\" -draw \"text $x_min,$y_min '${label}'\" -draw \"text $x_min,$y_max ' ${confidence} %'\""

            COUNTER["$label"]=$((${COUNTER["$label"]}+1))

          else
            test "$BE_VERBOSE" == "1" && echo "$label : not required or on ignore list"
          fi
        fi
      done

      if [ "$result_boxes" != "" ] ; then

        cameraname="${image_in/*\//}"
        cameraname="${cameraname/${CAMERA_NAME_DELIMINATOR}*/}"

        # NOTIFY
        test "$NOTIFY_URL" == "1" && notify_url "$cameraname" $PARALLEL
        test "$NOTIFY_ZONEMINDER" == "1" && notify_zoneminder "$cameraname" $PARALLEL

        filetime="$(stat -c %W "${image_in}")"
        if [ "$filetime" != "0" ] && [ "$filetime" != "0" ] ; then
          filetime="$(date -d "$filetime" 2> /dev/null)"
        fi
        filetime="$(date)"

        if [ "${DRAW_RESULTS,,}" == "yes" ] || [ "${DRAW_RESULTS,,}" == "true" ] || [ "${DRAW_RESULTS}" == "1" ] ; then
          eval gm convert "${image_in}" -font "$FONT" -fill none -strokewidth 1 -pointsize 16 $(echo "$result_boxes") -gravity SouthWest -draw \"fill blue stroke none text +5,+5 '$WATERMARK'\" -gravity NorthWest -draw \"fill blue stroke none text +15,+15 '${filetime}'\" -quality 82 "${image_out}"
        fi

        ALERT_NOW="$(date +%s)"
        if [[ $((ALERT_LAST + ALERT_PERIOD_SECONDS)) -lt $ALERT_NOW ]] || [[ $ALERT_COUNT -lt $ALERT_MAX_ALERTS ]] ; then
          if [[ ALERT_COUNT -ge $ALERT_MAX_ALERTS ]] ; then
            export ALERT_COUNT=1
          else
            export ALERT_COUNT=$((ALERT_COUNT+1))
          fi
          test "$DEBUG" == "1" && echo "ALERT!!"
          export ALERT_LAST="$ALERT_NOW"

          MESSAGE="$cameraname $filetime"
          for k in "${!COUNTER[@]}" ; do
            MESSAGE="${MESSAGE} $k:${COUNTER[$k]}"
          done

          test "$ALERT_PUSHOVER" == "1" && alert_pushover "${MESSAGE}" "${image_out}" $PARALLEL
          test "$ALERT_TELEGRAM" == "1" && alert_telegram "${MESSAGE}" "${image_out}" $PARALLEL
          test "$ALERT_WHATSMATE" == "1" && alert_whatsmate "${MESSAGE}" "${image_out}" $PARALLEL
          test "$ALERT_NEXMO" == "1" && alert_nexmo "${MESSAGE}" "${image_out}" $PARALLEL
          test "$ALERT_TWILIO" == "1" && alert_twilio "${MESSAGE}" "${image_out}" $PARALLEL

        else
          test "$DEBUG" == "1" && echo "NOALERT"
        fi
      fi

      if [ "${BACKUP_ORIGINAL}" == "1" ] ; then
        mv -f "$image_in" "${DIR_BACKUP}/${image_in/*\//}"
      else
        rm -f "$image_in"
      fi
      if [ "${SAVE_OUTPUT}" != "1" ] ; then
        rm -f "$image_out"
      fi

    else
      echo "ERROR: $res"
    fi
  else
    echo "ERROR: unable to read image: ${image_in}"
  fi

  test "$BE_VERBOSE" == "1" && echo "---->${RUN_COUNT} | AC ${ALERT_COUNT} @ ${ALERT_LAST}"
}

################
##### MAIN #####
################
if [ "$(which stat 2> /dev/null)" == "" ] ; then
  echo "ERROR: stat binary not found"
  exit 1
fi
if [ "$(which inotifywait 2> /dev/null)" == "" ] ; then
  echo "ERROR: inotifywait binary not found, install inotify-tools"
  exit 1
fi
if [ "$(which curl 2> /dev/null)" == "" ] ; then
  echo "ERROR: curl binary not found"
  exit 1
fi
if [ "$(which gm 2> /dev/null)" == "" ] ; then
  echo "ERROR: gm binary not found, install graphicsmagick"
  exit 1
fi
if [ "$(which nc 2> /dev/null)" == "" ] ; then
  echo "ERROR: nc binary not found, install netcat"
  exit 1
fi
if [ "$(which jq 2> /dev/null)" == "" ] ; then
  echo "ERROR: jq binary not found"
  exit 1
fi
if [ "$DIR_INPUT" == "" ] || [ "$DIR_INPUT" == "/" ] ; then
  echo "ERROR: DIR_INPUT is invalid"
  exit 1
fi
if [[ "${DEEPSTACK_URL,,}" != "http"* ]] ; then
  echo "ERROR: Invalid DEEPSTACK_URL"
  exit 1
fi
if [[ "${DEEPSTACK_BACKUP_URL,,}" != "http"* ]] && [ "$DEEPSTACK_BACKUP_URL" != "" ] ; then
  echo "ERROR: Invalid DEEPSTACK_BACKUP_URL"
  exit 1
fi

DEEPSTACK_URL="${DEEPSTACK_URL/\/v1\/vision\/detection*}"
DEEPSTACK_URL="${DEEPSTACK_URL%\/}"
if [ "$DEEPSTACK_BACKUP_URL" != "" ] ; then
  DEEPSTACK_BACKUP_URL="${DEEPSTACK_BACKUP_URL/\/v1\/vision\/detection*}"
  DEEPSTACK_BACKUP_URL="${DEEPSTACK_BACKUP_URL%\/}"
fi

# Process lists
IGNORE_LIST="${IGNORE_LIST//[[:space:]]}" #to lowercase and append ,
IGNORE_LIST="${IGNORE_LIST//;/,}" #replace ; with ,
IGNORE_LIST=",${IGNORE_LIST,,}," #to lowercase and append ,
NOTIFY_LIST="${NOTIFY_LIST//[[:space:]]}" #remove spaces
NOTIFY_LIST="${NOTIFY_LIST//;/,}" #replace ; with ,
NOTIFY_LIST=",${NOTIFY_LIST,,}," #to lowercase and append ,
VALID_IMAGE_EXTENSION_LIST="${VALID_IMAGE_EXTENSION_LIST//[[:space:]]}" #remove spaces
VALID_IMAGE_EXTENSION_LIST="${VALID_IMAGE_EXTENSION_LIST//;/,}" #replace ; with ,
VALID_IMAGE_EXTENSION_LIST=",${VALID_IMAGE_EXTENSION_LIST,,}," #to lowercase and append ,

# Globals
export RUN_COUNT=0
export ALERT_COUNT=0
export ALERT_LAST=0

# Assign bools
if [ "${DEBUG,,}" == "yes" ] || [ "${DEBUG,,}" == "true" ] || [ "${DEBUG,,}" == "1" ] ; then
  DEBUG="1"
  BE_VERBOSE="1"
  PARALLEL=""
else
  DEBUG="0"
  PARALLEL="&"
  if [ "${BE_VERBOSE,,}" == "yes" ] || [ "${BE_VERBOSE,,}" == "true" ] || [ "${BE_VERBOSE,,}" == "1" ] ; then
    BE_VERBOSE="1"
  else
    BE_VERBOSE="0"
  fi
fi
if [ "${SAVE_OUTPUT,,}" == "yes" ] || [ "${SAVE_OUTPUT,,}" == "true" ] || [ "${SAVE_OUTPUT,,}" == "1" ] ; then
  SAVE_OUTPUT="1"
else
  SAVE_OUTPUT="0"
fi
if [ "${BACKUP_ORIGINAL,,}" == "yes" ] || [ "${BACKUP_ORIGINAL,,}" == "true" ] || [ "${BACKUP_ORIGINAL,,}" == "1" ] ; then
  BACKUP_ORIGINAL="1"
else
  BACKUP_ORIGINAL="0"
fi
if [ "${ALERT_PUSHOVER,,}" == "yes" ] || [ "${ALERT_PUSHOVER,,}" == "true" ] || [ "${ALERT_PUSHOVER,,}" == "1" ] ; then
  ALERT_PUSHOVER="1"
else
  ALERT_PUSHOVER="0"
fi
if [ "${ALERT_TELEGRAM,,}" == "yes" ] || [ "${ALERT_TELEGRAM,,}" == "true" ] || [ "${ALERT_TELEGRAM,,}" == "1" ] ; then
  ALERT_TELEGRAM="1"
else
  ALERT_TELEGRAM="0"
fi
if [ "${ALERT_WHATSMATE,,}" == "yes" ] || [ "${ALERT_WHATSMATE,,}" == "true" ] || [ "${ALERT_WHATSMATE,,}" == "1" ] ; then
  ALERT_WHATSMATE="1"
else
  ALERT_WHATSMATE="0"
fi
if [ "${ALERT_NEXMO,,}" == "yes" ] || [ "${ALERT_NEXMO,,}" == "true" ] || [ "${ALERT_NEXMO,,}" == "1" ] ; then
  ALERT_NEXMO="1"
else
  ALERT_NEXMO="0"
fi
if [ "${ALERT_TWILIO,,}" == "yes" ] || [ "${ALERT_TWILIO,,}" == "true" ] || [ "${ALERT_TWILIO,,}" == "1" ] ; then
  ALERT_TWILIO="1"
else
  ALERT_TWILIO="0"
fi
if [ "${NOTIFY_ZONEMINDER,,}" == "yes" ] || [ "${NOTIFY_ZONEMINDER,,}" == "true" ] || [ "${NOTIFY_ZONEMINDER,,}" == "1" ] ; then
  NOTIFY_ZONEMINDER="1"
else
  NOTIFY_ZONEMINDER="0"
fi
if [ "${NOTIFY_URL,,}" == "yes" ] || [ "${NOTIFY_URL,,}" == "true" ] || [ "${NOTIFY_URL,,}" == "1" ] ; then
  NOTIFY_URL="1"
else
  NOTIFY_URL="0"
fi

mkdir -p "$DIR_INPUT"
if [ "${EMPTY_INPUT_DIR_ON_START,,}" == "yes" ] || [ "${EMPTY_INPUT_DIR_ON_START,,}" == "true" ] || [ "${EMPTY_INPUT_DIR_ON_START,,}" == "1" ] ; then
  test "$BE_VERBOSE" == "1" && echo "Emptying input dir: $DIR_INPUT"
  rm -f "${DIR_INPUT}/*.*"
  sync
fi
if [ "${SAVE_OUTPUT}" != "1" ] ; then
  DIR_OUTPUT="/tmp/deepstack"
fi
if [ "${BACKUP_ORIGINAL}" == "1" ] ; then
  mkdir -p "$DIR_BACKUP"
fi
mkdir -p "$DIR_OUTPUT"

echo "Watching: ${DIR_INPUT}"
inotifywait -m -e close_write,moved_to --exclude ".*(\.git|\.private|pr ivate|html|public_html|www|db|dbinfo|log|logs|sql|backup|backups|conf|config|configs)/" "${DIR_INPUT}" |
while read -r directory events filename; do
  extension="${filename//*.}"
  test "$DEBUG" == "1" && echo "${directory}${filename} : $events : $extension"
  #shellcheck disable=SC2076
  if [[ "$VALID_IMAGE_EXTENSION_LIST" =~ ",${extension,,}," ]] ; then
    test "$DEBUG" == "1" && echo "valid image extension detected...."
    process_image "${directory}${filename}" "$DIR_OUTPUT/${filename}"
  fi
  test "$DEBUG" == "1" && echo "====>${RUN_COUNT} | AC ${ALERT_COUNT} @ ${ALERT_LAST}"
done

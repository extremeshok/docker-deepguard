# docker-deepguard
camera monitoring and alerts using deepstack

https://hub.docker.com/r/extremeshok/deepstack

# Features
* Latest alpine with S6
* The power of Deepstack (machine learning / AI) to Guard your property
* Alerts to: pushover, telegram, whatsmate(whatsapp), nexmo(sms), twilio(sms)
* Limit alerts to prevent flooding, ie ALERT_MAX_ALERTS=2 in ALERT_PERIOD_SECONDS=120 (eg send a max of 2 alerts in 120seconds)
* Notify (Notifications/triggers) to: curl, zoneminder port

# Usage
* View **docker-compose-sample.yml** in the source repository for usage

# Note:
notifications are always sent, even when alerts are disabled, ie max alerts have been reached
notify is done before the alerts are sent
when debug mode is disabled, alerts and notifications are done in parallel (separate threads)

# ENVIRONMENT VARIBLES
### DEFAULTS
* IGNORE_LIST="person, bicycle, car, motorcycle, airplane, bus, train, truck, boat, trafficlight, firehydrant, stop_sign, parkingmeter, bench, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe, backpack, umbrella, handbag, tie, suitcase, frisbee, skis, snowboard, sportsball, kite, baseballbat, baseballglove, skateboard, surfboard, tennisracket, bottle, wineglass, cup, fork, knife, spoon, bowl, banana, apple, sandwich, orange, broccoli, carrot, hotdog, pizza, donot, cake, chair, couch, pottedplant, bed, diningtable, toilet, tv, laptop, mouse, remote, keyboard, cellphone, microwave, oven, toaster, sink, refrigerator, book, clock, vase, scissors, teddybear, hairdryer, toothbrush"
* NOTIFY_LIST="person, car, motorcycle, cat, bird, backpack, suitcase"
* VALID_IMAGE_EXTENSION_LIST="png, jpg, jpeg, gif, bmp"
* CAMERA_NAME_DELIMINATOR="."
* DIR_INPUT="/data/input"
* DIR_OUTPUT="/data/output"
* DIR_BACKUP="/data/backup"
* BACKUP_ORIGINAL="yes"
* SAVE_OUTPUT="yes"
* EMPTY_INPUT_DIR_ON_START="no"
* DRAW_RESULTS="yes"
* DEBUG="yes"
* BE_VERBOSE="yes"
* ALERT_MAX_ALERTS="2"
* ALERT_PERIOD_SECONDS="120"

## OPTIONS
* DEEPSTACK_URL="http://deepstack:5000"
* DEEPSTACK_BACKUP_URL="http://deepstackbak:5000"
* DEEPSTACK_CONFIDENCE_LIMIT="5"

### NOTIFY : zoneminder
* NOTIFY_ZONEMINDER="no"
* ZONEMINDER_NOFITY_HOST="zoneminder"
* ZONEMINDER_NOFITY_PORT="6802"

### NOTIFY : url
* NOTIFY_URL="no"
* URL_NOTIFY="http://blueiris/admin?trigger&camera=hd%%CAMERA%%&user=ai&pw=ai"

### ALERT : pushover
* ALERT_PUSHOVER="yes"
* PUSHOVER_TOKEN=""
* PUSHOVER_KEY=""
* PUSHOVER_PRIORITY="2" #2=emergency
* PUSHOVER_EXPIRE="600"
* PUSHOVER_RETRY="30"
* PUSHOVER_DEVICE=""
* PUSHOVER_SOUND="siren"

### ALERT : telegram
* ALERT_TELEGRAM="yes"
* TELEGRAM_TOKEN=""
* TELEGRAM_CHAT_ID=""

## ALERT : whatsmate (whatsapp)
* ALERT_WHATSMATE="no"
* WHATSMATE_CLIENT_ID=""
* WHATSMATE_CLIENT_SECRET=""
* WHATSMATE_WHATSAPP_NUMBER=""

## ALERT : nexmo (sms/text)
* ALERT_NEXMO="yes"
* NEXMO_API_KEY=""
* NEXMO_API_SECRET=""
* NEXMO_SMS_TO_NUMBER=""
* NEXMO_SMS_FROM=""

## ALERT : twilio (sms/text)
* ALERT_TWILIO="no"
* TWILIO_ACCOUNT_SID=""
* TWILIO_AUTH_TOKEN=""
* TWILIO_SMS_TO_NUMBER=""
* TWILIO_SMS_FROM=""

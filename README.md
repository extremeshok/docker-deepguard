# docker-deepguard
camera monitoring and alerts using deepstack

https://hub.docker.com/r/extremeshok/deepstack

# Features
Automatically fetch and update various geoip databases

View **docker-compose-sample.yml** in the source repository for usage

The power of Deepstack (machine learning / AI) to Guard your property.
watching every second of every minute of every hour of every day


Alerts to: pushover, telegram, whatsmate(whatsapp), nexmo(sms), twilio(sms)
Limit alerts to prevent flooding, ie ALERT_MAX_ALERTS=2 in ALERT_PERIOD_SECONDS=120 (eg send a max of 2 alerts in 120seconds)
Notify (Notifications/triggers) to: curl, zoneminder port

# note:
notifications are always sent, even when alerts are disabled, ie max alerts have been reached
notify is done before the alerts are sent

# MONITOR DIR
get camera name from files

# DEFAULTS
*

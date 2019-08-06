#!/usr/bin/env bash
mkdir -p /app/vendor/stunnel/var/run/stunnel/

cat > /app/vendor/stunnel/stunnel.conf << EOFEOF
foreground = yes

pid = /app/vendor/stunnel/stunnel4.pid

socket = r:TCP_NODELAY=1
options = NO_SSLv3
TIMEOUTidle = 86400
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH
debug = ${STUNNEL_LOGLEVEL:-notice}
EOFEOF

REDIS_JSON="$(echo "$VCAP_SERVICES" | jq .redis[0].credentials)"

URI_SCHEME=rediss
URI_USER=x
URI_HOST="$(echo "$REDIS_JSON" | jq -r .host)"
URI_PASSWORD="$(echo "$REDIS_JSON" | jq -r .password)"
URI_PORT="$(echo "$REDIS_JSON" | jq -r .port)"

echo $URI_HOST
echo "Setting REDIS_STUNNEL config var to $URI_SCHEME://$URI_USER:$URI_PASS@127.0.0.1:6379"
export REDIS_STUNNEL_URI=$URI_SCHEME://$URI_USER:$URI_PASS@127.0.0.1:URI_PORT

cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
[redis]
client = yes
accept = 127.0.0.1:$URI_PORT
connect = $URI_HOST:6379
retry = ${STUNNEL_CONNECTION_RETRY:-"no"}
EOFEOF

chmod go-rwx /app/vendor/stunnel/*

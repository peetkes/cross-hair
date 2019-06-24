#!/bin/bash
####################################################################
# This script aids with setting up a MarkLogic server
# running inside a docker container
####################################################################
CONFIG_FILE="${1}"
######################################################################
BOOTSTRAP_HOST=`hostname`
CURL="curl -s -S"
SKIP=0
RETRY_INTERVAL=5
N_RETRY=10
BOOTSTRAP_HOST_ENC="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$BOOTSTRAP_HOST")"
######################################################################
function restart_check {
  echo "Restart check for ${BOOTSTRAP_HOST}..."
  LAST_START=`$AUTH_CURL --max-time 1 -s "http://localhost:8001/admin/v1/timestamp"`
  for i in `seq 1 ${N_RETRY}`; do
    # continue as long as timestamp didn't change, or no output was returned
    if [ "$2" == "$LAST_START" ] || [ "$LAST_START" == "" ]; then
      sleep ${RETRY_INTERVAL}
      echo "Retrying..."
      LAST_START=`$AUTH_CURL --max-time 1 -s "http://localhost:8001/admin/v1/timestamp"`
    else
      return 0
    fi
  done
  echo "ERROR: Line $3: Failed to restart $1"
  exit 1
}
######################################################################
if [ -f $CONFIG_FILE ]; then
  printf "mlconfig script found. Running setup\n"
  source $CONFIG_FILE
  echo "     USER: ${USER}"
  echo " PASSWORD: ${PASSWORD}"
  echo "AUTH_MODE: ${AUTH_MODE}"
  echo "HOST_NAME: ${HOST_NAME}"
  echo "SEC_REALM: ${SEC_REALM}"
  echo "  VERSION: ${VERSION}"
  AUTH_CURL="${CURL} --${AUTH_MODE} --user ${USER}:${PASSWORD}"
  
  # (1) Initialize the server
  echo "Initializing $BOOTSTRAP_HOST..."
  $CURL -X POST -d "" http://localhost:8001/admin/v1/init
  sleep 10
  # (2) Initialize security and, optionally, licensing. Capture the last
  #     restart timestamp and use it to check for successful restart.
  echo "Initializing security for $BOOTSTRAP_HOST..."
  TIMESTAMP=`$CURL -X POST \
     -H "Content-type: application/x-www-form-urlencoded" \
     --data "admin-username=${USER}" --data "admin-password=${PASSWORD}" \
     --data "realm=${SEC_REALM}" \
     http://localhost:8001/admin/v1/instance-admin \
     | grep "last-startup" \
     | sed 's%^.*<last-startup.*>\(.*\)</last-startup>.*$%\1%'`
  if [ "$TIMESTAMP" == "" ]; then
    echo "ERROR: Failed to get instance-admin timestamp." >&2
    exit 1
  fi
  # Test for successful restart
  restart_check $BOOTSTRAP_HOST $TIMESTAMP $LINENO
    /sbin/service MarkLogic restart
  echo "Waiting for server restart.."
  sleep 5
  rm *.html
  echo "Initialization complete for $BOOTSTRAP_HOST..."
  exit 0
######################################################################
else
  printf "\n\nmlconfig script not found! Exiting initialization"
fi

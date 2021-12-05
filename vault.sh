#!/bin/bash
# The original keys to authenticate with are ~/.ssh/ttd-vault and ~/.ssh/ttd-vault.pub,
# and the private key to use for ssh'ing is ~/.ssh/ttd-vault-temp-cert
#
# https://atlassian.thetradedesk.com/confluence/display/EN/SSH+Certificate+Based+Authentication

KEYFILE=${HOME}/.ssh/ttd-vault
CERT_TO_GENERATE=${KEYFILE}-temp-key # This is the private key you will use to log into TTD nodes
export VAULT_ADDR=https://vault.adsrvr.org

set -e

if [[ ! -f ${KEYFILE} || ! -f ${KEYFILE}.pub ]]; then
  echo "You must have private key file ${KEYFILE} and public key file ${KEYFILE}.pub. You may copy one of your existing keys to these."
  echo 'Or you may generate a new one with: ssh-keygen -t rsa -b 2048 -C "ttd-email-address"'
  exit 1
fi

if [[ ! -z $1 && "$1" == '-f' ]]; then
  echo 'removing vault files'
  rm -f "${KEYFILE}.login-semaphore"
  rm -f "${KEYFILE}.pubkey-semaphore"
  rm -f "${CERT_TO_GENERATE}"
fi

FILE=${KEYFILE}.login-semaphore
THIRTY_DAYS=2592000
if [[ ! -f ${FILE} || $(($(date +%s)-$(date -r ${FILE} +%s))) -gt $THIRTY_DAYS ]]; then
  echo 'logging in'
  vault login -method=oidc  -path=ops-sso
  touch $FILE
fi

FILE=${KEYFILE}.pubkey-semaphore
NINE_HOURS=32400
if [[ ! -f ${FILE} || $(($(date +%s)-$(date -r ${FILE} +%s))) -gt $NINE_HOURS ]]; then
  echo "vault write"
  vault write \
        -field=signed_key \
        ssh-client-signer/sign/ops_sso_user \
        valid_principals=$(whoami) \
        public_key=@${KEYFILE}.pub > ${CERT_TO_GENERATE}
  chmod 600 ${CERT_TO_GENERATE}
  touch $FILE
fi

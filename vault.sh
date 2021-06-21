#!/bin/bash
# The original keys to authenticate with are ~/.ssh/ttd-vault and ~/.ssh/ttd-vault.pub,
# and the private key to use for ssh'ing is ~/.ssh/ttd-vault-temp-cert

KEYFILE=${HOME}/.ssh/ttd-vault
CERT_TO_GENERATE=${KEYFILE}-temp-key # This is the private key you will use to log into TTD nodes
export VAULT_ADDR=https://vault.adsrvr.org

echo $KEYFILE
echo $CERT_TO_GENERATE

set -e

if [[ ! -f ${KEYFILE} || ! -f ${KEYFILE}.pub ]]; then
  echo "You must have private key file ${KEYFILE} and public key file ${KEYFILE}.pub. You may copy one of your existing keys to these."
  exit 1
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
  vault write -field=signed_key \
        ssh-client-signer/sign/ops_sso_user valid_principals=$(whoami) \
        public_key=@${KEYFILE}.pub > ${CERT_TO_GENERATE}
  touch $FILE
fi

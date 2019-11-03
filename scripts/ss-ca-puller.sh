#!/usr/bin/env bash

## This script pulls in SSL Certificates and spits em into the certificate store for Java

set -e
## set -x	## Uncomment for debugging

echo ""
echo -e "Starting SSL Certificate import...\n"

for CERT in "$@"
do
  echo "Pulling SSL certificate for ${CERT}..."
  FILENAME=${CERT//":"/".p"}
  CERTNAME=${FILENAME//"."/"-"}
  echo "Q" | openssl s_client -connect ${CERT} 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/$FILENAME.pem
  
  echo "Importing certificate to keystore..."
  keytool -list -storepass changeit -keystore $JAVA_HOME/jre/lib/security/cacerts -alias $CERTNAME
  if [ $? -eq 0 ]; then
    echo "Certificate already exists, skipping..."
  else
    echo "Certificate not in keystore, importing..."
    keytool -import -noprompt -storepass changeit -file /tmp/$FILENAME.pem -alias $CERTNAME -keystore $JAVA_HOME/jre/lib/security/cacerts
  fi
  echo ""
done
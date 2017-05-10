#!/bin/bash
set -e

openssl version

# Use this command on the target host:
wget -O Dynatrace-OneAgent-Linux-1.117.255.sh \
     https://hek37999.live.dynatrace.com/installer/oneagent/unix/latest/QSSP55KtStY9rzBN

# Verify signature:
wget https://ca.dynatrace.com/dt-root.cert.pem
( echo 'Content-Type: multipart/signed; protocol="application/x-pkcs7-signature"; micalg="sha-256"; boundary="--SIGNED-INSTALLER"\n\n----SIGNED-INSTALLER' ; cat Dynatrace-OneAgent-Linux-1.117.255.sh ) | openssl cms -verify -CAfile dt-root.cert.pem > /dev/null

# And run the installer with root rights:
/bin/sh Dynatrace-OneAgent-Linux-1.117.255.sh APP_LOG_CONTENT_ACCESS=1

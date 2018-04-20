#!/bin/bash

die() { echo "$@" 1>&2 ; exit 1; }

kcadm=$JBOSS_HOME/bin/kcadm.sh

#########################################
# Login
#########################################
$kcadm config credentials --server http://localhost:8080/auth --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD
[ $? = 0 ] || die "Unable to login"

#########################################
# Getting realm keys
#########################################
$kcadm get keys -r $KC_REALM_NAME
[ $? = 0 ] || die "Unable to get realm keys"

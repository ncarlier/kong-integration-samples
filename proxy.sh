#!/bin/bash

die() { echo "$@" 1>&2 ; exit 1; }

ctn_id=`docker-compose ps -q | head -n 1`
[ -z "$ctn_id" ] && die "No container seems to be deployed. Abort!"

net_name=$(docker inspect \
  --format='{{range $p, $conf := .NetworkSettings.Networks}} {{$p}} {{end}}' \
  $ctn_id)
[ -z "$net_name" ] && die "Network name not found. Abort!"

net_id=$(docker network ls -f driver=bridge | grep $net_name | cut -f 1 -d " ")
[ -z "$net_id" ] && die "Network ID not found. Abort!"

##########################
# Setup the Firewall rules
##########################
fw_setup() {
  echo -n "Add pre-routing rule for interface: br-$net_id ... "
  sudo iptables -t nat -A PREROUTING -i br-$net_id -p tcp -j REDSOCKS
  echo "done."
}

##########################
# Clear the Firewall rules
##########################
fw_clear() {
  echo -n "Remove pre-routing rule for interface: br-$net_id ... "
  sudo iptables -t nat -D PREROUTING -i br-$net_id -p tcp -j REDSOCKS
  echo "done."
}

case "$1" in
    start)
        echo "Setting REDSOCKS firewall rules..."
        fw_clear
        fw_setup
        echo "done."
        ;;
    stop)
        echo "Cleaning REDSOCKS firewall rules..."
        fw_clear
        echo "done."
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
exit 0

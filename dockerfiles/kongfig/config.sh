die() { echo "$@" 1>&2 ; exit 1; }

host=$KONG_HOST
[ -z "$host" ] && die "HOST not set. Beware to call this script with Make!"

#########################################
# Configuration
#########################################
kongfig apply --path /etc/kong.yml --host $KONG_HOST:$KONG_PORT
[ $? = 0 ] || die "Unable to apply Kong configuration"

echo "Kong successfully configured."


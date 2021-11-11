#!/bin/bash

source .env
CACHE="-v hardhat-cache:/app/cache"
TIMEOUT=2h
HEIGHT=
NAME=`uuidgen`

print_help () {
  echo
  echo "options:"
  echo "-b     Fork from block number (Default: latest, minus safety value - 5). Should be 2675000 at least."
  echo "-h     Print this Help."
  echo "-n     Disable cache loading."  
  echo "-t     Custom timeout (default: 2h)."
  echo
  echo "example: ./fork.sh -n -b 2675000 -t 30m"
  echo
  exit 0
}

while getopts 'nb:ht:' flag; do
  case "${flag}" in
    n) CACHE= ;;
    b) HEIGHT="--fork-block-number ${OPTARG}";;
    h) print_help ;;
    t) TIMEOUT="${OPTARG}" ;;
    *) print_help
       exit 1 ;;
  esac
done

docker run -d \
--network hardhat_default $CACHE \
-l "traefik.enable=true" \
-l "traefik.http.middlewares.$NAME.headers.customrequestheaders.Access-Control-Allow-Origin=*" \
-l "traefik.http.routers.$NAME.service=$NAME" \
-l "traefik.http.routers.$NAME.rule=Host(\`${DOMAIN}\`) && Path(\`/$NAME/\`)" \
-l "traefik.http.routers.$NAME.entrypoints=websecure" \
-l "traefik.http.routers.$NAME.tls.certresolver=myresolver" \
-l "traefik.http.services.$NAME.loadbalancer.server.port=8545" \
--name $NAME hardhat-node npx hardhat node \
--fork $DEFAULT_RPC $HEIGHT \
1> /dev/null

nohup sleep $TIMEOUT &>/dev/null && docker stop $NAME &>/dev/null && docker rm $NAME &>/dev/null &

echo
echo "Access URL:"
echo -e "=======> \033[4m\033[1mhttps://${DOMAIN}/$NAME/\033[0m\033[0m"

echo
echo -e "Auto remove after: \033[1m$TIMEOUT\033[0m. To manual remove:"
echo "=======> docker stop $NAME && docker rm $NAME"
echo

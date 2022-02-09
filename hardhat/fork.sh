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
  echo "-d     Disable cache loading."
  echo "-t     Custom timeout (default: 2h)."
  echo "-n     Custom container name (default: random uuid)."
  echo
  echo "example: ./fork.sh -d -b 2675000 -t 30m"
  echo
  exit 0
}

while getopts 'db:ht:n:' flag; do
  case "${flag}" in
    d) CACHE= ;;
    b) HEIGHT="--fork-block-number ${OPTARG}";;
    h) print_help ;;
    t) TIMEOUT="${OPTARG}" ;;
    n) NAME="${OPTARG}" ;;
    *) print_help
       exit 1 ;;
  esac
done

docker run --rm -d \
--network hardhat_default $CACHE \
-l "traefik.enable=true" \
-l "traefik.http.middlewares.$NAME.headers.customrequestheaders.Access-Control-Allow-Origin=*" \
-l "traefik.http.routers.$NAME.service=$NAME" \
-l "traefik.http.routers.$NAME.rule=Host(\`${DOMAIN}\`) && Path(\`/$NAME/\`)" \
-l "traefik.http.routers.$NAME.entrypoints=websecure" \
-l "traefik.http.routers.$NAME.tls.certresolver=myresolver" \
-l "traefik.http.services.$NAME.loadbalancer.server.port=8545" \
--name $NAME hardhat-node timeout $TIMEOUT npx hardhat node \
--fork $DEFAULT_RPC $HEIGHT \
1> /dev/null

docker run --rm --name=explorer-$NAME -tid \
-e RPC=https://${DOMAIN}/$NAME/ \
-e SUBDIR=explorer-$NAME \
-l "traefik.enable=true" \
-l "traefik.http.routers.explorer-$NAME.service=explorer-$NAME" \
-l "traefik.http.routers.explorer-$NAME.rule=Host(\`${DOMAIN}\`) && PathPrefix(\`/explorer-$NAME\`)" \
-l "traefik.http.routers.explorer-$NAME.entrypoints=websecure" \
-l "traefik.http.routers.explorer-$NAME.tls.certresolver=myresolver" \
-l "traefik.http.services.explorer-$NAME.loadbalancer.server.port=8000" \
etherparty timeout $TIMEOUT ./docker-entrypoint.sh 1> /dev/null

echo
echo "RPC URL:"
echo -e "=======> \033[4m\033[1mhttps://${DOMAIN}/$NAME/\033[0m\033[0m"

echo
echo "Explorer URL:"
echo -e "=======> \033[4m\033[1mhttps://${DOMAIN}/explorer-$NAME/\033[0m\033[0m"

echo
echo -e "Container logs:"
echo "=======> docker logs -f --tail 100 $NAME"
echo "=======> docker logs -f --tail 100 explorer-$NAME"

echo
echo -e "Auto remove after: \033[1m$TIMEOUT\033[0m. To manual remove:"
echo "=======> docker stop $NAME; docker stop explorer-$NAME"

echo
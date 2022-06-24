#!/bin/bash

source .env
TIMEOUT=2h
NAME=
CHAIN=1

declare -A CHAINS=( [1]=mainnet [5]=goerli [10]=optimistic [56]=bsc [100]=gnosis [137]=polygon [42161]=arbitrum )

print_help () {
  echo
  echo "options:"
  echo "-b     Fork from block number (Default: latest, minus safety value - 5)."
  echo "-c     Custom chain name or id (default: mainnet or 1)."
  echo "-h     Print this Help."
  echo "-t     Custom timeout (default: 2h)."
  echo "-n     Custom container name (default: random uuid)."
  echo
  echo "example 1: ./fork.sh -t 2d -n my-fork -c bsc"
  echo "fork will be removed after 2 days, access url https://"${DOMAIN}"/my-fork/"
  echo
  exit 0
}

while getopts 'b:c:ht:n:' flag; do
  case "${flag}" in
    b) HEIGHT="${OPTARG}";;
    c) CHAIN="${OPTARG}";;
    h) print_help ;;
    t) TIMEOUT="${OPTARG}" ;;
    n) NAME="${OPTARG}" ;;
    *) print_help
       exit 1 ;;
  esac
done

for KEY in "${!CHAINS[@]}"; do
    if [[ ${CHAINS[$KEY]} == "$CHAIN" ]]; then
        CHAIN=$KEY
        break
    fi
done

re='^[0-9]+$'
if ! [[ $CHAIN =~ $re ]] ; then 
   echo "ERROR: Unknown chain" $CHAIN". Try to use chain id." >&2; exit 1 
fi

if [ -z "$NAME" ]
then
    NAME=`uuidgen`
else
    FORK_NAME=`curl -s -H "Accept: application/json" -H "X-Access-Key: ${TENDERLY_ACCESS_KEY}" https://api.tenderly.co/api/v1/account/${TENDERLY_USER}/project/${TENDERLY_PROJECT}/forks | jq -r '.simulation_forks[]|select(.description=="'$NAME'")|.id'`
fi

if [ ! -z "$FORK_NAME" ]
then
    curl -X DELETE -H "Accept: application/json" -H "X-Access-Key: ${TENDERLY_ACCESS_KEY}" https://api.tenderly.co/api/v2/project/${TENDERLY_PROJECT}/forks/$FORK_NAME &> /dev/null && echo -e "Killed a fork with the same name: \033[1m$NAME\033[0m"
fi

docker stop $NAME &> /dev/null && echo -e "Killed a container with the same name: \033[1m$NAME\033[0m"
docker stop explorer-$NAME &> /dev/null && echo -e "Killed a container with the same name: \033[1mexplorer-$NAME\033[0m"

if [ -z "$HEIGHT" ]
then
    FORK_NAME=`curl -s -X POST --data '{"description": "'$NAME'", "network_id": "'$CHAIN'"}' -H "Accept: application/json" -H "X-Access-Key: ${TENDERLY_ACCESS_KEY}" https://api.tenderly.co/api/v1/account/${TENDERLY_USER}/project/${TENDERLY_PROJECT}/fork | jq -r '.simulation_fork.id'`
else
    FORK_NAME=`curl -s -X POST --data '{"description": "'$NAME'", "network_id": "'$CHAIN'", "block_number": '$HEIGHT'}' -H "Accept: application/json" -H "X-Access-Key: ${TENDERLY_ACCESS_KEY}" https://api.tenderly.co/api/v1/account/${TENDERLY_USER}/project/${TENDERLY_PROJECT}/fork | jq -r '.simulation_fork.id'`
fi

docker run --rm -d \
--network hardhat_default \
-e SUBDIR=$NAME \
-e URL=https://rpc.tenderly.co/fork/$FORK_NAME \
-e TIMEOUT=$TIMEOUT \
-l "traefik.enable=true" \
-l "traefik.http.middlewares.$NAME.headers.customrequestheaders.Access-Control-Allow-Origin=*" \
-l "traefik.http.routers.$NAME.service=$NAME" \
-l "traefik.http.routers.$NAME.rule=Host(\`${DOMAIN}\`) && PathPrefix(\`/$NAME/\`)" \
-l "traefik.http.routers.$NAME.entrypoints=websecure" \
-l "traefik.http.routers.$NAME.tls.certresolver=myresolver" \
-l "traefik.http.services.$NAME.loadbalancer.server.port=8080" \
--name $NAME proxy \
1> /dev/null

docker run --rm --name=explorer-$NAME -tid \
-e RPC=https://rpc.tenderly.co/fork/$FORK_NAME \
-e SUBDIR=explorer-$NAME \
-l "traefik.enable=true" \
-l "traefik.http.routers.explorer-$NAME.service=explorer-$NAME" \
-l "traefik.http.routers.explorer-$NAME.rule=Host(\`${DOMAIN}\`) && PathPrefix(\`/explorer-$NAME\`)" \
-l "traefik.http.routers.explorer-$NAME.entrypoints=websecure" \
-l "traefik.http.routers.explorer-$NAME.tls.certresolver=myresolver" \
-l "traefik.http.services.explorer-$NAME.loadbalancer.server.port=8000" \
etherparty timeout $TIMEOUT ./docker-entrypoint.sh 1> /dev/null

nohup sleep $TIMEOUT &>/dev/null && curl -X DELETE -H "Accept: application/json" -H "X-Access-Key: ${TENDERLY_ACCESS_KEY}" https://api.tenderly.co/api/v2/project/${TENDERLY_PROJECT}/forks/$FORK_NAME &>/dev/null &

echo
echo "RPC URL:"
echo -e "=======> \033[4m\033[1mhttps://${DOMAIN}/$NAME/\033[0m\033[0m"
echo "Tenderly RPC URL:"
echo -e "=======> \033[4m\033[1mhttps://rpc.tenderly.co/fork/$FORK_NAME\033[0m\033[0m"

echo
echo "Explorer URL:"
echo -e "=======> \033[4m\033[1mhttps://${DOMAIN}/explorer-$NAME/\033[0m\033[0m"

echo
echo -e "Container logs:"
echo "=======> docker logs -f --tail 100 $NAME"
echo "=======> docker logs -f --tail 100 explorer-$NAME"

echo
echo -e "HTTP requests capture:"
echo "=======> docker exec -it $NAME tcpflow -p -c port 8080"

echo
echo -e "Auto remove after: \033[1m$TIMEOUT\033[0m. To manual remove:"
echo "=======> docker stop $NAME; docker stop explorer-$NAME"

echo
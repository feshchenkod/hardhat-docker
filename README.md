# fork-docker
# option 1 - manual

## build images and create volume:
Build hardhat image:
```bash
docker build --no-cache -t hardhat-node . -f Dockerfile.hardhat
```

Build anvil image:
```bash
docker pull ghcr.io/foundry-rs/foundry:nightly
docker build --no-cache -t anvil-node . -f Dockerfile.anvil
```

Build proxy (for tenderly) image:
```bash
docker build --no-cache -t proxy . -f Dockerfile.proxy
```

Create caching volume:
```bash
docker volume create hardhat-cache
```

## run hardhat:
```bash
docker run --rm -d \
-v hardhat-cache:/app/cache \
-p 8545:8545 \
-e RPC_URL=$DEFAULT_RPC \
--name $NAME hardhat-node
```

## custom env:
```
-e HEIGHT=$HEIGHT
-e INTERVAL=$INTERVAL
```

# option 2 - fork script

## build images:
Build hardhat image:
```bash
docker build --no-cache -t hardhat-node . -f Dockerfile.hardhat
```

Build anvil image:
```bash
docker pull ghcr.io/foundry-rs/foundry:nightly
docker build --no-cache -t anvil-node . -f Dockerfile.anvil
```

Build proxy (for tenderly) image:
```bash
docker build --no-cache -t proxy . -f Dockerfile.proxy
```

Create caching volume:
```bash
docker volume create hardhat-cache
```

## build block explorer:
```bash
git clone https://github.com/feshchenkod/explorer.git
cd explorer
docker build -t etherparty .
```

## run traefic proxy:
```bash
mv example_env .env
docker-compose up -d
```

## run fork:
### run hardhat:
```
$ ./fork.sh -h

options:
-b     Fork from block number (Default: latest, minus safety value - 5). Should be 2675000 at least.
-h     Print this Help.
-d     Disable cache loading.
-t     Custom timeout (default: 2h).
-n     Custom container name (default: random uuid).
-i     Set mining interval in ms (default: none).

example 1: ./fork.sh -t 2d -n my-fork
fork will be removed after 2 days, access url https://DOMAIN/my-fork/

example 2: ./fork.sh -d -b 2675000 -t 30m -i 5000
```

### run anvil:
```
$ ./anvil.sh -h

options:
-b     Fork from block number (Default: latest, minus safety value - 5). Should be 2675000 at least.
-h     Print this Help.
-d     Disable caching.
-t     Custom timeout (default: 2h).
-n     Custom container name (default: random uuid).
-i     Set mining interval in seconds (default: none, set 5 at least).

example 1: ./anvil.sh -t 2d -n my-fork
fork will be removed after 2 days, access url https://DOMAIN/my-fork/

example 2: ./anvil.sh -d -b 2675000 -t 30m -i 6
```

### run tenderly:
```
$ ./tendedrly.sh -h

options:
-b     Fork from block number (Default: latest, minus safety value - 5).
-c     Custom chain name or id (default: mainnet or 1).
-h     Print this Help.
-t     Custom timeout (default: 2h).
-n     Custom container name (default: random uuid).

example 1: ./fork.sh -t 2d -n my-fork -c bsc
fork will be removed after 2 days, access url https://DOMAIN/my-fork/
```
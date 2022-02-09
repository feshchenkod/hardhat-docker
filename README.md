# hardhat-docker

## build hardhat:
```bash
mv .example_env .env
docker build -t hardhat-node .
docker-compose up -d
docker volume create hardhat-cache
```

## build explorer:

```bash
git clone https://github.com/feshchenkod/explorer.git
cd explorer
docker build -t etherparty .
```

## run fork:
```bash
$ ./fork.sh -h

options:
-b     Fork from block number (Default: latest, minus safety value - 5). Should be 2675000 at least.
-h     Print this Help.
-d     Disable cache loading.
-t     Custom timeout (default: 2h).
-n     Custom container name (default: random uuid).

example: ./fork.sh -d -b 2675000 -t 30m
```
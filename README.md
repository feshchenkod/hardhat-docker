# hardhat-docker

```
mv .example_env .env
docker build -t hardhat-node .
docker-compose up -d
docker volume create hardhat-cache
./fork.sh -h
```
# fork-docker

Docker-based infrastructure for running **forked EVM networks** using **Hardhat**, **Anvil**, or **Tenderly**, with optional caching, block explorer, and reverse proxy.

---

## Option 1 — Run Hardhat from prebuilt image

### 1. Pull image

```bash
docker pull ghcr.io/feshchenkod/hardhat:latest
```
### 2. Run Hardhat node

#### Start (minimal)
```bash
docker run --rm -d \
  -p 8545:8545 \         
  -e RPC_URL=$DEFAULT_RPC \
  ghcr.io/feshchenkod/hardhat:latest
```
> `RPC_URL` **must be an archive RPC endpoint**.

#### Start with parameters

Create cache volume (optional):

```bash
docker volume create hardhat-cache
```

Run node:

```bash
docker run --rm -d \
  -p 8545:8545 \
  -v hardhat-cache:/app/cache \
  -e RPC_URL=$DEFAULT_RPC \
  -e HEIGHT=24000000 \
  -e INTERVAL=5000 \
  --name hardhat \
  ghcr.io/feshchenkod/hardhat:latest
```

**Parameters**

* `RPC_URL` — archive RPC endpoint (**required**)
* `HEIGHT` — fork block number

  > Must be ≥ `2675000`
* `INTERVAL` — mining interval in milliseconds

  > Disabled if not set
* `hardhat-cache` volume — speeds up fork startup by caching RPC data

---

## Option 2 — Run fork via scripts

This option gives more flexibility and supports:

* Hardhat
* Anvil
* Proxy
* Automatic cleanup
* Traefik routing
* Block explorer

---

## Build images

### Hardhat

```bash
docker build --no-cache -t hardhat-node . -f Dockerfile.hardhat
```

### Anvil

```bash
docker pull ghcr.io/foundry-rs/foundry:nightly
docker build --no-cache -t anvil-node . -f Dockerfile.anvil
```

### Proxy

```bash
docker build --no-cache -t proxy . -f Dockerfile.proxy
```

### Cache volume

```bash
docker volume create hardhat-cache
```

---

## Build block explorer (optional)

```bash
git clone https://github.com/feshchenkod/explorer.git
cd explorer
docker build -t etherparty .
```

---

## Run Traefik proxy

```bash
mv example_env .env
docker-compose up -d
```

This enables access via URLs like:

```
https://DOMAIN/<fork-name>/
```

---

## Run forked networks

### Hardhat fork

```bash
./fork.sh -h
```

#### Options

```
-b     Fork from block number
       Default: latest - safety offset (5 blocks)
       Minimum recommended: 2675000

-d     Disable cache loading
-t     Fork lifetime (default: 2h)
-n     Container name (default: random UUID)
-i     Mining interval in ms (default: disabled)
-h     Show help
```

#### Examples

```bash
./fork.sh -t 2d -n my-fork
```

Fork will be removed after 2 days
Access URL: `https://DOMAIN/my-fork/`

```bash
./fork.sh -d -b 2675000 -t 30m -i 5000
```

---

### Anvil fork

```bash
./anvil.sh -h
```

#### Options

```
-b     Fork from block number
       Default: latest - safety offset (5 blocks)
       Minimum recommended: 2675000

-d     Disable cache
-t     Fork lifetime (default: 2h)
-n     Container name (default: random UUID)
-i     Mining interval in seconds (minimum: 5)
-h     Show help
```

#### Examples

```bash
./anvil.sh -t 2d -n my-fork
```

```bash
./anvil.sh -d -b 2675000 -t 30m -i 6
```

---

### Tenderly-compatible fork

```bash
./tenderly.sh -h
```

#### Options

```
-b     Fork from block number
       Default: latest - safety offset (5 blocks)

-c     Chain name or chain ID
       Default: mainnet / 1

-t     Fork lifetime (default: 2h)
-n     Container name (default: random UUID)
-h     Show help
```

#### Example

```bash
./tenderly.sh -t 2d -n my-fork -c bsc
```

Fork will be removed after 2 days
Access URL: `https://DOMAIN/my-fork/`

---

## Notes & Best Practices

* Disable cache (`-d`) if RPC data consistency is critical
* Use long-lived forks (`-t`) for debugging or demos
* Prefer Anvil for performance-sensitive workloads
* Hardhat is better for compatibility with existing HH tooling
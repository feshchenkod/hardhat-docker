#!/bin/bash

if [ ! -z "${HEIGHT}" ]; then
    FORK_BLOCK="--fork-block-number ${HEIGHT}"
fi

if [ ! -z "${INTERVAL}" ]; then
    sed -i '/hardhatMainnet: {/,/^[[:space:]]*},[[:space:]]*$/ {
        /^[[:space:]]*},[[:space:]]*$/i \
        mining: { auto: true, interval: '"${INTERVAL}"' },
    }' hardhat.config.ts
    sed -i '/hardhatMainnet: {/a \
      automine: true,\
      intervalMining: '"${INTERVAL}"',
    ' hardhat.config.ts
fi

exec npx hardhat node --fork ${RPC_URL} $FORK_BLOCK
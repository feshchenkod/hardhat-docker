#!/bin/bash

if [ ! -z "${HEIGHT}" ]; then
    sed -i '/forking:[[:space:]]*{/,/^[[:space:]]*},[[:space:]]*$/ {
      /^[[:space:]]*},[[:space:]]*$/i\
        blockNumber: '"${HEIGHT}"'
    }' hardhat.config.ts
fi

if [ ! -z "${INTERVAL}" ]; then
    sed -i '/forking:[[:space:]]*{/i\
      mining: { auto: true, interval: '"${INTERVAL}"' },
    ' hardhat.config.ts
fi

exec npx hardhat node --network hardhat
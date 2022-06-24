#!/bin/bash

if [ ! -z "${HEIGHT}" ]; then
    FORK_BLOCK="--fork-block-number ${HEIGHT}"
fi

if [ ! -z "${INTERVAL}" ]; then
    echo "module.exports={networks:{hardhat:{chainId:1,initialBaseFeePerGas:1000000000,blockGasLimit:50000000,mining:{auto: true,interval: ${INTERVAL}}}}}" >> hardhat.config.js
else
    echo "module.exports={networks:{hardhat:{chainId:1,initialBaseFeePerGas:1000000000,blockGasLimit:50000000}}}" >> hardhat.config.js
fi

exec npx hardhat node --fork ${RPC_URL} $FORK_BLOCK
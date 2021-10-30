FROM node:14
WORKDIR /app
RUN yarn init -y && \
    yarn add hardhat
RUN echo "module.exports={networks:{hardhat:{chainId:1}}}" >> hardhat.config.js
# ADD hardhat.config.js .
EXPOSE 8545
CMD npx hardhat node --fork $RPC_URL
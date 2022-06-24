FROM node:14

WORKDIR /app

RUN yarn init -y && \
    yarn add hardhat && \
    npm install --save-dev @nomiclabs/hardhat-ganache

RUN apt-get update && apt-get install -y \
  tcpflow \
  && rm -rf /var/lib/apt/lists/*

COPY ./docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

CMD ["./docker-entrypoint.sh"]
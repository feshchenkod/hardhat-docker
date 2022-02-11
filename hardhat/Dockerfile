FROM node:14

WORKDIR /app

RUN yarn init -y && \
    yarn add hardhat

COPY ./docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

EXPOSE 8545

CMD ["./docker-entrypoint.sh"]
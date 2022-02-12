FROM ethereum/solc:0.8.7 as dependencies

FROM node:16

WORKDIR /src

COPY ./package.json /src/package.json
COPY --from=dependencies /usr/bin/solc /usr/bin/solc
COPY . .

RUN npm install
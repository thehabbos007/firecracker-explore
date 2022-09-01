FROM rust:1.63.0-alpine3.16 as build

WORKDIR /var/

COPY init-agent .

RUN cargo build --release

FROM node:lts-alpine3.16

RUN mkdir -p /home/node/build
RUN chown -R 1000:1000 /home/node

RUN apk add --no-cache git openssh curl

RUN touch /usr/local/share/.yarnrc
RUN mkdir -p /usr/local/share/.cache/yarn

RUN chown -R 1000:1000 //usr/local/share/.yarnrc
RUN chown -R 1000:1000 //usr/local/share/.cache/yarn

COPY --from=build /var/target/x86_64-unknown-linux-musl/release/init-agent /init-agent

FROM rust:1.63.0-alpine3.16 as build

WORKDIR /var/

COPY init-agent .

RUN cargo build --release

FROM node:lts-alpine3.16

# RUN mkdir -p /home/node/tmp
# RUN mkdir -p /home/node/cache
RUN mkdir -p /home/node/build
# RUN mkdir -p /home/node/global
RUN chown -R 1000:1000 /home/node

RUN apk add --no-cache git openssh curl

RUN touch /usr/local/share/.yarnrc
run mkdir -p /usr/local/share/.cache/yarn
# RUN echo "--global-folder /home/node/global" >> /usr/local/share/.yarnrc
# RUN echo "--no-bin-links" >> /usr/local/share/.yarnrc

RUN chown -R 1000:1000 //usr/local/share/.yarnrc
RUN chown -R 1000:1000 //usr/local/share/.cache/yarn

# RUN echo "UUID=116154ec-9b15-4341-a8a8-fffef734ac4d /home/node ext4 defaults 0 0" >> /etc/fstab
# RUN echo "UUID=116154ec-9b15-4341-a8a8-fffef734ac4d /tmp ext4 defaults 0 0" >> /etc/fstab
# RUN echo "UUID=116154ec-9b15-4341-a8a8-fffef734ac4d /usr/local/share ext4 defaults 0 0" >> /etc/fstab


COPY --from=build /var/target/x86_64-unknown-linux-musl/release/init-agent /init-agent

# --- base

FROM elixir:1.13-alpine AS base

RUN apk add --no-cache \
    bash \
    build-base \
    inotify-tools \
    libsodium-dev \
    make \
    nodejs \
    npm \
    openssl \
    tzdata

RUN ln -s /usr/share/zoneinfo/UTC /etc/localtime

# --- local

FROM base AS local

ARG UID
ARG USER
RUN adduser -u $UID -D -h /home/$USER -s /bin/bash $USER

RUN mkdir -p /epi-contacts/assets/node_modules && \
    mkdir -p /epi-contacts/_build && \
    mkdir -p /epi-contacts/deps && \
    chown -R $USER /epi-contacts

WORKDIR /epi-contacts

USER $USER

# these install to user home dirs
RUN mix local.hex --force && \
    mix local.rebar --force

# just for kenichi
RUN echo 'set editing-mode vi' >> /home/$USER/.inputrc

ARG OBAN_KEY
RUN mix hex.organization auth oban --key $OBAN_KEY

# --- test

FROM local AS test
USER root
RUN apk add --no-cache chromium-chromedriver
ARG USER
USER $USER

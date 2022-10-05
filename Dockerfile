FROM ruby:3.1

RUN set -ex \
    && apt update \
    && apt install -y --no-install-recommends \
        build-essential libgirepository1.0-dev libpoppler-glib-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /app

COPY Gemfile *.lock /app/

WORKDIR /app
RUN bundle install
RUN bundle binstubs --all --path /bin

COPY . /app

ENV HISTCONTROL=ignoreboth:erasedups

ENTRYPOINT ["bash"]

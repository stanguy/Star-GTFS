FROM debian:jessie AS build_vendors

RUN apt-get update && apt-get install -y git autoconf bison curl patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev libdb-dev uuid-dev libpq-dev
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
ENV RBENV_ROOT=/rbenv
ENV RBENV_VERSION=1.9.3-p551
ENV PATH=$RBENV_ROOT/bin/:$RBENV_ROOT/shims/:$PATH

RUN git clone https://github.com/rbenv/rbenv.git /rbenv && git clone https://github.com/rbenv/ruby-build.git "$(/rbenv/bin/rbenv root)"/plugins/ruby-build

RUN rbenv install 1.9.3-p551 && rbenv global 1.9.3-p551

RUN mkdir /app
WORKDIR /app
ADD Gemfile* ./
RUN gem install bundler -v "~>1.0" && \
    rbenv rehash && \
    bundle install && \
    rbenv rehash

FROM debian:jessie

# runtime libs and netcat for waiting
RUN apt-get update && apt-get install -y libgdbm3 libpq5 nodejs netcat

RUN adduser --home /app --uid 1000 rails

COPY --from=build_vendors /rbenv/ /rbenv/
ENV RBENV_ROOT=/rbenv
ENV RBENV_VERSION=1.9.3-p551
ENV PATH=$RBENV_ROOT/bin/:$RBENV_ROOT/shims/:$PATH

USER rails
WORKDIR /app

CMD ["containers/app/wait-for", "database:5432", "--", "containers/app/run-server.sh"]

FROM debian:buster AS build_vendors

RUN apt-get update && apt-get install -y git autoconf bison curl patch build-essential rustc libssl-dev libyaml-dev libreadline-dev zlib1g-dev libgmp-dev libncurses-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev libpq-dev
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
ENV RBENV_ROOT=/rbenv
ENV RBENV_VERSION=2.2.9
ENV PATH=$RBENV_ROOT/bin/:$RBENV_ROOT/shims/:$PATH

RUN git clone https://github.com/rbenv/rbenv.git /rbenv && git clone https://github.com/rbenv/ruby-build.git "$(/rbenv/bin/rbenv root)"/plugins/ruby-build

RUN rbenv install ${RBENV_VERSION} && rbenv global ${RBENV_VERSION}

RUN mkdir /app
WORKDIR /app
ADD Gemfile* ./
RUN gem install bundler -v "~>1.0" && \
    rbenv rehash && \
    bundle install && \
    rbenv rehash

FROM debian:buster

# runtime libs and netcat for waiting
RUN apt-get update && apt-get install -y libreadline7 libncurses6 libgdbm6 libpq5 libyaml-0-2 nodejs netcat

RUN adduser --home /app --uid 1000 rails

COPY --from=build_vendors /rbenv/ /rbenv/
ENV RBENV_ROOT=/rbenv
ENV RBENV_VERSION=2.2.9
ENV PATH=$RBENV_ROOT/bin/:$RBENV_ROOT/shims/:$PATH

RUN chown -R rails /rbenv

USER rails
WORKDIR /app

CMD ["containers/app/wait-for", "database:5432", "--", "containers/app/run-server.sh"]

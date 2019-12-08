ARG PYTHON_VERSION=3.6

# ~~~~~~~~ Base - ubuntu ~~~~~~~~~~
FROM python:${PYTHON_VERSION} as base-ubuntu

RUN pip install --upgrade pip \
    && apt-get update && apt-get install -y --no-install-recommends \
    ipython \
    pkg-config \
    libxml2-dev \
    libxslt1-dev \
    libfreetype6-dev \
    libgirepository1.0-dev \
    libpng-dev \
    libpq-dev \
    python-dev \
    libcairo2 \
    libssl-dev \
    gcc \
    libffi-dev \
    swig \
    libjpeg-dev \
    zlib1g-dev \
    build-essential

# ~~~~~~~~ Base - alpine ~~~~~~~~~~
FROM python:${PYTHON_VERSION}-alpine as base-alpine

RUN pip install --upgrade pip \
    && apk upgrade --no-self-upgrade --available \
    && apk add ipython \
    pkgconfig \
    libxml2-dev \
    libxslt-dev \
    freetype-dev \
    gobject-introspection-dev \
    libpng-dev \
    postgresql-dev \
    python-dev \
    cairo-dev \
    openssl-dev \
    gcc \
    libffi-dev \
    swig \
    jpeg-dev \
    zlib-dev \
    build-base

# ~~~~~~~~ Development ~~~~~~~~~~
FROM base-ubuntu as dev
ENV PYTHONUNBUFFERED 1

VOLUME ["/root/.faraday"]
VOLUME ["/app"]

COPY requirements.txt ./
COPY requirements_server.txt ./
COPY requirements_extras.txt ./
COPY requirements_dev.txt ./
RUN pip install --no-cache-dir pycairo \
    && pip install --no-use-pep517 --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -r requirements_server.txt \
    && pip install --no-cache-dir -r requirements_extras.txt \
    && pip install --no-cache-dir -r requirements_dev.txt \
    && rm /requirements.txt \
    && rm /requirements_server.txt \
    && rm /requirements_extras.txt \
    && rm /requirements_dev.txt \
    && mkdir -p /root/.faraday

WORKDIR /app


# ~~~~~~~~ Build ~~~~~~~~~~
from base-alpine as build
ENV PYTHONUNBUFFERED 1

COPY . /src/
WORKDIR /src/
RUN pip install --user .


# ~~~~~~~~ Production - release ~~~~~~~~~~
FROM python:${PYTHON_VERSION}-alpine as prod

LABEL maintainer="Jürgen Löhel <juergen@loehel.de>" \
  org.label-schema.name="faraday" \
  org.label-schema.vendor="infobyte" \
  org.label-schema.schema-version="1.0"

ENV PYTHONUNBUFFERED 1

COPY ./docker/faraday/entrypoint /entrypoint
COPY ./docker/faraday/start /start
COPY --from=build /root/.local/ /usr/share/faraday/.local/

RUN apk upgrade --no-self-upgrade --available \
    && apk add bash libpq libjpeg  \
    && pip install --upgrade pip \
    && mkdir -p /usr/share/faraday/.faraday \
    && ln -s /usr/share/faraday/.local/bin/faraday-server /usr/bin/faraday-server \
    && ln -s /usr/share/faraday/.local/bin/faraday-client /usr/bin/faraday-client \
    && ln -s /usr/share/faraday/.local/bin/faraday-manage /usr/bin/faraday-manage \
    && ln -s /usr/share/faraday/.local/bin/faraday-searcher /usr/bin/faraday-searcher \
    && ln -s /usr/share/faraday/.local/bin/fplugin /usr/bin/fplugin \
    && addgroup -S faraday \
    && adduser -S -G faraday -h /usr/share/faraday -s /usr/sbin/nologin faraday \
    && chown -R faraday:faraday /usr/share/faraday/ \
    && chmod u+x /entrypoint \
    && chmod u+x /start \
    && chown faraday /entrypoint \
    && chown faraday /start

VOLUME ["/usr/share/faraday/.faraday"]

USER faraday
WORKDIR /usr/share/faraday/

ENTRYPOINT ["/entrypoint"]

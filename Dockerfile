FROM resin/raspberrypi2-python:3.5
MAINTAINER JB Kopecky <jb.kopecky@gmail.com>

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    sudo git \
    tesseract-ocr tesseract-ocr-eng imagemagick ghostscript unpaper libmagic-dev\
    && rm -rf /var/lib/apt/lists/*

# Clone and install paperless
ENV PAPERLESS_COMMIT 9ea39aeecb4f806b55c751c0702190fa604f6ff9
RUN mkdir -p /usr/src/paperless \
    && git clone https://github.com/danielquinn/paperless.git /usr/src/paperless \
    && (cd /usr/src/paperless && git checkout -q $PAPERLESS_COMMIT) \
    && (cd /usr/src/paperless && pip3 install --no-cache-dir -r requirements.txt) \
    # Change `DEBUG` and `ALLOWED_HOSTS`
    && sed -i 's/DEBUG = True/DEBUG = False/' /usr/src/paperless/src/paperless/settings.py \
    && sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \[\'\*\'\]/" /usr/src/paperless/src/paperless/settings.py

# Create directories
RUN mkdir -p /usr/src/paperless/data
RUN mkdir -p /usr/src/paperless/media/documents/originals
RUN mkdir -p /usr/src/paperless/media/documents/thumbnails

# Set consumption directory
ENV PAPERLESS_CONSUMPTION_DIR /consume
RUN mkdir -p $PAPERLESS_CONSUMPTION_DIR

# Migrate database
WORKDIR /usr/src/paperless/src
RUN ./manage.py migrate

# Create user
RUN groupadd -g 1000 paperless \
    && useradd -u 1000 -g 1000 -d /usr/src/paperless paperless \
    && chown -Rh paperless:paperless /usr/src/paperless

# Setup entrypoint
RUN cp /usr/src/paperless/scripts/docker-entrypoint.sh /sbin/docker-entrypoint.sh \
    && chmod 755 /sbin/docker-entrypoint.sh

# Mount volumes
VOLUME ["/usr/src/paperless/data", "/usr/src/paperless/media", "/consume"]

ENTRYPOINT ["/sbin/docker-entrypoint.sh"]
CMD ["--help"]

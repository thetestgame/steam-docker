# steam dedicated server for docker.
# https://developer.valvesoftware.com/wiki/SteamCMD#Linux.2FOS_X

FROM ubuntu:latest

ENV SERVER_DIR=/data/server \
    STEAM=/steam \
    PLATFORM=windows \
    STEAM_APP_ID=0 \
    UPDATE_OS=1 \
    UPDATE_STEAM=1 \
    UPDATE_SERVER=1 \
    PUID=1000 \
    PGID=1000 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

COPY docker /docker

RUN export LANG=en_US.UTF-8 && \
    export LANGUAGE=en_US.UTF-8 && \
    export LC_ALL=en_US.UTF-8 && \
    export DEBIAN_FRONTEND=noninteractive && \
    export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=true && \
    apt-get --quiet update && \
    # Set UTF-8 Locale
    apt-get install --yes --install-recommends 2> /dev/null \
      locales \
      apt-utils && \
    sed --in-place --expression='s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    /usr/sbin/locale-gen 2> /dev/null && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    # Add wine
    dpkg --add-architecture i386 && \
    apt-get --quiet update && \
    apt-get --quiet --yes upgrade && \
    apt-get install --yes --install-recommends \
      software-properties-common \
      lib32gcc1 \
      wine-stable \
      wine32 \
      wine64 \
      xvfb && \
    # Auto-accept license and install steamcmd.
    echo steam steam/license note '' | debconf-set-selections && \
    echo steam steam/question select 'I AGREE' | debconf-set-selections && \
    apt-get install --yes --install-recommends \
      steamcmd && \
    # Create steam user and setup permissions.
    useradd --create --home ${STEAM} steam && \
    su steam -c " \
      cd ${STEAM} && \
		  steamcmd +quit" && \
    mkdir -p /data && \
    chown -R steam:steam ${STEAM} /data /docker && \
    chmod 0755 /docker/* && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rfv /var/lib/{apt,dpkg} /var/lib/{cache, log}

WORKDIR /data

VOLUME /data

ENTRYPOINT /docker/startup

# For ports required by steam servcies, see:
# https://support.steampowered.com/kb_article.php?ref=8571-GLVN-8711
# Be sure to include any server-specific ports.
EXPOSE 27015/tcp 27015/udp 27016/udp

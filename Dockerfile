#----- base source builder ----------------------------------------------------
FROM debian:stable-slim as base-builder

LABEL mainttiner="anguyen@computer.org"

# gnu build system
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential autoconf automake libtool pkg-config \
        curl git ca-certificates

#----- openconnect source buidler ---------------------------------------------
FROM base-builder as openconnect-builder

WORKDIR /build

ARG OPENCONNECT_VERSION
ARG VPNC_SCRIPTS_DATE

ENV OPENCONNECT_VERSION=${OPENCONNECT_VERSION:-8.10}
ENV VPNC_SCRIPTS_DATE=${VPNC_SCRIPTS_DATE:-20200930}

# openconnect deps
RUN apt-get install -y --no-install-recommends \
        libxml2-dev libssl-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

# download, build pre-prep
RUN curl -L https://github.com/openconnect/openconnect/archive/v${OPENCONNECT_VERSION}.tar.gz | \
    tar -xzp

WORKDIR /build/openconnect-${OPENCONNECT_VERSION}

RUN curl -L ftp://ftp.infradead.org/pub/vpnc-scripts/vpnc-scripts-${VPNC_SCRIPTS_DATE}.tar.gz | \
    tar -xzp && \
    mkdir /etc/vpnc && \
    cp vpnc-scripts-${VPNC_SCRIPTS_DATE}/vpnc-script /etc/vpnc/ && \
    cp /etc/vpnc/vpnc-script /build/

# configure, make, install
RUN mkdir -p build/usr && \
    ./autogen.sh && \
    ./configure --prefix $(pwd)/build/usr --disable-nls && \
    make -j 4 && \
    make install && \
    cd build && \
    tar -czf /build/openconnect.tar.gz .

WORKDIR /build

RUN rm -rf openconnect-${OPENCONNECT_VERSION}

#----- tunsocks source buidler ------------------------------------------------

FROM base-builder as tunsocks-builder

WORKDIR /build

ARG TUNSOCKS_HASH

ENV TUNSOCKS_HASH=${TUNSOCKS_HASH:-882779fba768b7325cc0aa4ad5286ac66ff0bfdf}

# tunsocks deps
RUN apt-get install -y --no-install-recommends \
        libevent-dev && \
    rm -rf /var/lib/apt/lists/*

COPY udptapif.patch .

# download and build tunsocks
RUN git clone https://github.com/russdill/tunsocks.git && \
    cd tunsocks && \
    git reset --hard ${TUNSOCKS_HASH} && \
    git submodule init && \
    git submodule update && \
    cd .. && \
    patch tunsocks/lwip-libevent/netif/udptapif.c udptapif.patch

WORKDIR /build/tunsocks

RUN mkdir -p build/usr && \
    ./autogen.sh && \
    ./configure --prefix $(pwd)/build/usr && \
    make -j 4 && \
    make install && \
    cd build && \
    tar -czf /build/tunsocks.tar.gz .

WORKDIR /build

RUN rm -rf tunsocks

#----- minimal image ----------------------------------------------------------

FROM debian:stable-slim

# openconnect deps
RUN apt-get update && apt-get install -y --no-install-recommends \
      libxml2 openssl libevent-2.1-6 ca-certificates \
      procps less net-tools && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /etc/vpnc

COPY --from=openconnect-builder /build/openconnect.tar.gz /
COPY --from=openconnect-builder /build/vpnc-script /etc/vpnc/vpnc-script
COPY --from=tunsocks-builder /build/tunsocks.tar.gz /
COPY docker-entrypoint.sh /

RUN tar -xzf openconnect.tar.gz && \
    rm openconnect.tar.gz && \
    tar -xzf tunsocks.tar.gz && \
    rm tunsocks.tar.gz && \
    chmod 0755 /docker-entrypoint.sh && \
# default openssl.cnf is too restrictive
    rm /etc/ssl/openssl.cnf && \
    echo 'hosts: files dns' > /etc/nsswitch.conf

EXPOSE 8080/tcp
EXPOSE 9000/tcp
EXPOSE 22222/udp

ENTRYPOINT ["/docker-entrypoint.sh"]

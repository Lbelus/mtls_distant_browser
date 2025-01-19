FROM ubuntu:latest

ENV DEBIAN_FRONTEND=non-interactive

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    git \
    curl \
    wget \
    libssl-dev \
    libnss3-dev \
    zlib1g-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ambrop72/badvpn.git /badvpn

# Build only tun2socks and udpgw components
WORKDIR /badvpn/build
RUN cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_NOTHING_BY_DEFAULT=1 \
    -DBUILD_TUN2SOCKS=1 \
    -DBUILD_UDPGW=1 && \
    make && \
    make install

# Copy the binaries for external use
RUN mkdir -p /output && cp /usr/local/bin/* /output/

CMD ["true"]

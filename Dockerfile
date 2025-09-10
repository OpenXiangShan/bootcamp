# official codercom/code-server is based on debian:bookworm, but we prefer ubuntu
FROM lscr.io/linuxserver/code-server:4.103.2

# we need python3.9 for GEM5, we can get it from deadsnakes/ppa
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa

# install dependencies for XiangShan
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # tools
        git \
        tree \
        time \
        curl \
        # build toolchain
        autoconf \
        build-essential \
        make \
        cmake \
        flex \
        bison \
        m4 \
        scons \
        gcc-11 \
        gcc \
        g++ \
        gcc-riscv64-linux-gnu \
        verilator \
        clang \
        llvm \
        mold \
        pkg-config \
        python3-pip \
        device-tree-compiler \
        # runtime
        openjdk-21-jre \
        # libraries
        libreadline6-dev \
        libsdl2-dev \
        zlib1g \
        zlib1g-dev \
        sqlite3 \
        libsqlite3-dev \
        zstd \
        libzstd-dev \
        protobuf-compiler \
        libprotobuf-dev \
        libprotoc-dev \
        libgoogle-perftools-dev \
        libboost-all-dev \
        python3.9-dev \
        && \
    apt-get clean

# install mill
RUN curl -L https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/1.0.4/mill-dist-1.0.4-mill.sh -o /usr/bin/mill && \
    chmod +x /usr/bin/mill

# install jupyter
RUN python3 -m pip install --break-system-packages \
        jupyter \
        notebook \
        matplotlib

# use gcc-11 and g++-11 as default gcc and g++ for GEM5
# also use python3.9-config as default python3-config for GEM5 scons script
RUN rm /usr/bin/python3-config && \
    ln -s /usr/bin/python3.9-config /usr/bin/python3-config

# install extensions for code-server
# RUN /app/code-server/bin/code-server --install-extension ms-toolsai.jupyter && \
#     /app/code-server/bin/code-server --install-extension ms-python.python && \
#     /app/code-server/bin/code-server --install-extension scalameta.metals && \
#     curl -L https://github.com/Lramseyer/vaporview/releases/download/v1.4.1-beta/vaporview-1.4.0.vsix -o /tmp/vaporview.vsix && \
#     /app/code-server/bin/code-server --install-extension /tmp/vaporview.vsix && \
#     rm /tmp/vaporview.vsix

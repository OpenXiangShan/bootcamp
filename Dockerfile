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
        gawk \
        # build toolchain
        autoconf \
        build-essential \
        make \
        cmake \
        flex \
        bison \
        m4 \
        scons \
        verilator \
        clang \
        llvm \
        mold \
        pkg-config \
        python3-pip \
        device-tree-compiler \
        # install gcc 11 to sync with our server environment
        gcc-11 \
        g++-11 \
        gcc-11-riscv64-linux-gnu \
        # runtime
        openjdk-21-jre \
        # libraries
        libc6-dev-riscv64-cross \
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
        # for performance analysis scripts
        matplotlib \
        numpy \
        pandas \
        scipy

# use gcc-11 to sync with our server environment
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100 && \
    update-alternatives --install /usr/bin/riscv64-linux-gnu-gcc riscv64-linux-gnu-gcc /usr/bin/riscv64-linux-gnu-gcc-11 100

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

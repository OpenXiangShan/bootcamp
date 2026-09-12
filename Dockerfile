ARG BASE_IMAGE=ghcr.io/openxiangshan/bootcamp:base-env
FROM ${BASE_IMAGE}

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && \
    apt install -y --no-install-recommends \
        python3-pip

# install jupyter etc.
# keep python3-psutil managed by apt (installed in xs-env)
RUN python3 -m pip install \
        --no-cache-dir \
        --break-system-packages \
        --ignore-installed psutil \
        jupyter \
        notebook \
        # for performance analysis scripts
        matplotlib \
        numpy \
        pandas \
        scipy

# install extensions for code-server
RUN mkdir -p /config/extensions && \
    /app/code-server/bin/code-server --extensions-dir /config/extensions --install-extension ms-python.python && \
    /app/code-server/bin/code-server --extensions-dir /config/extensions --install-extension ms-toolsai.jupyter && \
    /app/code-server/bin/code-server --extensions-dir /config/extensions --install-extension scalameta.metals && \
    /app/code-server/bin/code-server --extensions-dir /config/extensions --install-extension lramseyer.vaporview && \
    /app/code-server/bin/code-server --extensions-dir /config/extensions --install-extension qwtel.sqlite-viewer

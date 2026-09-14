ARG BASE_IMAGE=ghcr.io/openxiangshan/bootcamp:base-env
FROM ${BASE_IMAGE}

# install jupyter etc.
# ignore python3-psutil etc. managed by apt (installed in xs-env)
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

# Clear CMD from xs-env
CMD []

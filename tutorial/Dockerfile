ARG BASE_IMAGE=ghcr.io/openxiangshan/bootcamp:latest
FROM ${BASE_IMAGE}

RUN python3 -m pip install \
        --no-cache-dir \
        --break-system-packages \
        --ignore-installed psutil \
        jupyterlab \
        jupyterlab-rise

COPY root /

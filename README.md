# XiangShan bootcamp

Accelerate your agile hardware development with XiangShan!
This bootcamp teaches you how to build, run, and experiment with the XiangShan out-of-order processor, giving you hands-on experience with one of the most advanced open-source CPUs.

## Prerequisites

### Bare metal
<!-- TODO: detailed description for prerequisites -->

- Install Python.
- Install Jupyter Notebook.
- Run `download_assets.sh` to download/extract necessary assets from our GitHub release page.
- Use [Jupyter extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter) in [VSCode](https://code.visualstudio.com)/[code-server](https://github.com/coder/code-server) is recommended.
- Install dependencies to run/build XiangShan (e.g. `gcc`, `libsqlite3-dev`), please refer to [xs-env](https://docs.xiangshan.cc/zh-cn/latest/tools/xsenv) documentation for details.

### Code-server (Docker)

- Install Docker & Docker compose.
- Run `docker-compose up -d` to start the code-server container.
  - Refer to [linuxserver/docker-code-server](https://github.com/linuxserver/docker-code-server#usage) for description of environment variables.
- Access code-server at `http://localhost:8443` (default no password).

## LICENSE

This repo is licensed under CC BY 4.0.

Copyright © 2025 The XiangShan Team

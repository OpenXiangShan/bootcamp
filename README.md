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
- Access code-server at `http://localhost:8443` (default no password).

#### Enviroment variables

Basically inherited from [linuxserver/code-server](https://github.com/linuxserver/docker-code-server#usage)

| Env | Default | Description |
| --- | ------- | ----------- |
| `PUID` | `1000` | uid in docker |
| `PGID` | `1000` | gid in docker |
| `TZ` | `Etc/UTC` | Timezone in docker |
| (`HASHED_`)`PASSWORD` | unset | (hashed) password for code-server, no auth if leave empty, refer to [official doc](https://github.com/coder/code-server/blob/main/docs/FAQ.md#can-i-store-my-password-hashed) to generate hash |
| `SUDO_PASSWORD`(`_HASH`) | `password` | (hashed) password for `sudo`, use `openssl passwd -6 <password>` to generate hash |
| `PROXY_DOMAIN` | unset | Refer to [official doc](https://github.com/coder/code-server/blob/main/docs/guide.md#using-a-subdomain) |
| `DEFAULT_WORKSPACE` | unset | Path of default workspace opened in code-server |
| `PWA_APPNAME` | unset | Name of [PWA](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps) app |

Note: if both hashed and plain password is set, the hashed one will take effect.

## Assets

We have some pre-built binaries, workloads, emu outputs, etc. to speed up the bootcamp experience.

Those files are hosted on our [GitHub release page](https://github.com/OpenXiangShan/bootcamp/releases).

You can run `download_assets.sh <asset name>` to download/extract necessary assets. If you don't specify the asset name, all assets will be downloaded.

Please note that these assets are large files (several GBs after extraction), please make sure you have a stable network connection and enough disk space.

- emu-precompile: Pre-built XiangShan binaries you can directly run emulation with. And pre-built NEMU shared library for difftest.
- gem5-precompile: Pre-built NEMU shared library for difftest.
- workload: Workloads, coremark, hello world, etc..
- emu-perf-result: XiangShan emulation results, including performance metrics and logs.
- emu-spec-topdown-result: XiangShan emulation results when running SPEC CPU2006 checkpoints, including top-down performance metrics and logs.
- gem5-spec-topdown-result: GEM5 simulation results when running SPEC CPU2006 checkpoints, including top-down performance metrics and logs.

Our notebook supports download required assets automatically, you can just run the notebook directly.

## LICENSE

This repo is licensed under CC BY 4.0.

Copyright © 2025 The XiangShan Team

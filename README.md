# Kiwix server
Offline Wikipedia or any zim file

## Uses
- [Kiwix](https://kiwix.org)
- [Podman](https://podman.io) with systemd
- [jq](https://jqlang.org) for reading configuration file
- [curl](https://curl.se/) for downloading files
- [Makefile](https://www.gnu.org/software/make/manual/make.html) as a bash runner
- [cron](https://fr.wikipedia.org/wiki/Cron) for regular auto-update

## Features
- Configurable zim files sources
- Auto-update kiwix and zim files
- Run as a dedicated user (run rootless, needs sudo to install)

## Configuration

### System
Edit `Makefile`

- Change the value of `RUN_USER` to customize the system user running kiwix-server
- Change the value of `RUN_DIR` to customize the directory where application files are stored (config, zim files, logs)

Or keep the default values

### Sources
Edit `config.json`

The auto-update process get the listing of available files from `base_url`, download the most recent file beginning with `base_file` and make it available to the kiwix server.

### ZIM files sources
- https://dumps.wikimedia.org/other/kiwix/zim/
- https://download.kiwix.org/zim/

## Install

- On a Debian-based Linux (Debian, Ubuntu, Linux Mint, ...)

```
sudo apt-get install git make
git clone https://github.com/gautiers/kiwix-server.git .
make install
```
Open http://127.0.0.1:8080


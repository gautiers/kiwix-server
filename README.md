# Kiwix server
Offline Wikipedia or any zim file

## Uses
- [Kiwix](https://kiwix.org)
- [Podman](https://podman.io) with systemd
- [jq](https://jqlang.org) for reading configuration file
- [Makefile](https://www.gnu.org/software/make/manual/make.html) as a bash runner

## Features
- Configurable zim files sources
- Auto-update kiwix and zim files
- Run as a user (run rootless, needs sudo to install)

## Install

On a Debian-based Linux (Debian, Ubuntu, Linux Mint, ...) logged in with the user you want to run the kiwix server with.

```
sudo apt-get install git make
git clone https://github.com/gautiers/kiwix-server.git .
make install
```
Open http://127.0.0.1:8080

## Configuration

Edit `config.json`

The auto-update process get the listing of available files from `base_url`, download the most recent file beginning with `base_file` and make it available to the kiwix server.

### ZIM files sources
- https://dumps.wikimedia.org/other/kiwix/zim/
- https://download.kiwix.org/zim/
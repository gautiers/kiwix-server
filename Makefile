SHELL := /bin/bash
.PHONY: *
.SILENT:

start:
	DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$${UID}/bus \
	systemctl --user start kiwix-server.service

stop:
	DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$${UID}/bus \
	systemctl --user stop kiwix-server.service

status:
	DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$${UID}/bus \
	systemctl --user status kiwix-server.service

update_software:
	podman pull ghcr.io/kiwix/kiwix-serve

update_zim_files:
	jq --compact-output ".zim_files.[]" config.json | while read SOURCE; do \
		BASE_URL=$$(jq --raw-output ".base_url" <<< "$${SOURCE}"); \
		BASE_FILE=$$(jq --raw-output ".base_file" <<< "$${SOURCE}"); \
		LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | sed -r 's/.*href="([^"]+).*/\1/g'); \
		if ! [ -f "./zim_files/$${LATEST}" ]; then \
			echo "downloading $${LATEST}"; \
			wget --directory-prefix=./zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}; \
			[ -f ./zim_files/$${BASE_FILE}_latest.zim ] && rm ./zim_files/$${BASE_FILE}_latest.zim; \
			ln -s $${LATEST} ./zim_files/$${BASE_FILE}_latest.zim; \
		fi; \
	done;

install_prerequisites:
	sudo apt-get install -y wget curl jq podman sudo

install_service:
	sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $${USER}
	podman system migrate
	sudo mkdir -p /etc/containers/systemd/users/$${UID}
	cat kiwix-server.container.template \
		| sed "s|{KIWIX-SERVER_BASE}|$$(pwd)|g" \
		| sudo tee /etc/containers/systemd/users/$${UID}/kiwix-server.container >/dev/null
	systemctl --user daemon-reload

install_cron:
	echo "0 7 * * * $${USER} cd $$(pwd) && make update 2>&1 | sed \"s|^|\$$(date -Iseconds) |\" >> $$(pwd)/logs/updates.cron.log" \
		| sudo tee /etc/cron.d/kiwix-server_update >/dev/null

update: update_software update_zim_files stop start
install: install_prerequisites install_service install_cron update

SHELL := /bin/bash
.PHONY: *
.SILENT:

RUN_USER := kiwix-server
RUN_DIR := $$(pwd)/run

start:
	if [ "$$(id -un)" == "${RUN_USER}" ]; then \
		XDG_RUNTIME_DIR=/run/user/$$(id -u ${RUN_USER}) \
		systemctl --user start kiwix-server.service; \
	else \
		sudo -u ${RUN_USER} XDG_RUNTIME_DIR=/run/user/$$(id -u ${RUN_USER}) \
		systemctl --user start kiwix-server.service; \
	fi;

stop:
	if [ "$$(id -un)" == "${RUN_USER}" ]; then \
		XDG_RUNTIME_DIR=/run/user/$$(id -u ${RUN_USER}) \
		systemctl --user stop kiwix-server.service; \
	else \
		sudo -u ${RUN_USER} XDG_RUNTIME_DIR=/run/user/$$(id -u ${RUN_USER}) \
		systemctl --user stop kiwix-server.service; \
	fi;

status:
	if [ "$$(id -un)" == "${RUN_USER}" ]; then \
		XDG_RUNTIME_DIR=/run/user/$$(id -u ${RUN_USER}) \
		systemctl --user status kiwix-server.service; \
	else \
		sudo -u ${RUN_USER} XDG_RUNTIME_DIR=/run/user/$$(id -u ${RUN_USER}) \
		systemctl --user status kiwix-server.service; \
	fi;

update_software:
	podman pull ghcr.io/kiwix/kiwix-serve

update_zim_files:
	jq --compact-output ".zim_files.[]" ${RUN_DIR}/config.json | while read SOURCE; do \
		BASE_URL=$$(jq --raw-output ".base_url" <<< "$${SOURCE}"); \
		BASE_FILE=$$(jq --raw-output ".base_file" <<< "$${SOURCE}"); \
		LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | sed -r 's/.*href="([^"]+).*/\1/g'); \
		if ! [ -f "${RUN_DIR}/zim_files/$${LATEST}" ]; then \
			echo "downloading $${LATEST}"; \
			wget --directory-prefix=${RUN_DIR}/zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}; \
			[ -f ${RUN_DIR}/zim_files/$${BASE_FILE}_latest.zim ] && rm ${RUN_DIR}/zim_files/$${BASE_FILE}_latest.zim; \
			ln -s $${LATEST} ${RUN_DIR}/zim_files/$${BASE_FILE}_latest.zim; \
		fi; \
	done;

install:
	getent passwd ${RUN_USER} >/dev/null || sudo useradd --system --add-subids-for-system ${RUN_USER} --create-home; \
	sudo loginctl enable-linger ${RUN_USER}; \
	sudo mkdir -p ${RUN_DIR}/{logs,zim_files}; \
	sudo cp config.json ${RUN_DIR}/; \
	sudo chown -R $$(id -u ${RUN_USER}):$$(id -g ${RUN_USER}) ${RUN_DIR}; \
	sudo mkdir -p /etc/containers/systemd/users/$$(id -u ${RUN_USER}); \
	cat kiwix-server.container.template \
		| sed "s|{KIWIX-SERVER_BASE}|${RUN_DIR}|g" \
		| sudo tee /etc/containers/systemd/users/$$(id -u ${RUN_USER})/kiwix-server.container >/dev/null; \
	sleep 1; \
	sudo -u ${RUN_USER} \
		XDG_RUNTIME_DIR=/run/user/$$(id -u ${RUN_USER}) \
		systemctl --user daemon-reload;

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
#install: install_prerequisites install_service install_cron update

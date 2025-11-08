SHELL := /bin/bash
.PHONY: *
.SILENT:
.ONESHELL:

RUN_USER := kiwix-server
RUN_DIR := $$(pwd)/run

define include_runas
	runas () {
		if [ "$$(id -un)" == "${RUN_USER}" ]; then
			XDG_RUNTIME_DIR=/run/user/$$(id -u ${RUN_USER}) $$@
		else
			sudo -u ${RUN_USER} XDG_RUNTIME_DIR=/run/user/$$(id -u ${RUN_USER}) $$@
		fi
	}
endef

start:
	$(include_runas)
	runas systemctl --user start kiwix-server.service

stop:
	$(include_runas)
	runas systemctl --user stop kiwix-server.service

status:
	$(include_runas)
	runas systemctl --user status kiwix-server.service

update_software:
	$(include_runas)
	runas podman pull --quiet ghcr.io/kiwix/kiwix-serve

update_zim_files:
	$(include_runas)
	runas jq --compact-output ".zim_files.[]" ${RUN_DIR}/config.json | while read SOURCE; do
		BASE_URL=$$(jq --raw-output ".base_url" <<< "$${SOURCE}")
		BASE_FILE=$$(jq --raw-output ".base_file" <<< "$${SOURCE}")
		LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | sed -r 's/.*href="([^"]+).*/\1/g')
		if ! runas [ -f "${RUN_DIR}/zim_files/$${LATEST}" ]; then
			echo "downloading $${LATEST}"
			runas wget --directory-prefix=${RUN_DIR}/zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}
			runas [ -f ${RUN_DIR}/zim_files/$${BASE_FILE}_latest.zim ] && runas rm ${RUN_DIR}/zim_files/$${BASE_FILE}_latest.zim
			runas ln -s $${LATEST} ${RUN_DIR}/zim_files/$${BASE_FILE}_latest.zim
			sleep 1
		fi
	done

install_prerequisites:
	sudo apt-get install -y wget curl jq podman sudo >/dev/null

install_service:
	$(include_runas)
	getent passwd ${RUN_USER} >/dev/null || sudo useradd --system --add-subids-for-system ${RUN_USER} --create-home
	sudo loginctl enable-linger ${RUN_USER}
	sudo mkdir -p ${RUN_DIR}/{logs,zim_files}
	sudo cp config.json ${RUN_DIR}/
	sudo chown -R $$(id -u ${RUN_USER}):$$(id -g ${RUN_USER}) ${RUN_DIR}
	sudo mkdir -p /etc/containers/systemd/users/$$(id -u ${RUN_USER})
	cat kiwix-server.container.template \
		| sed "s|{KIWIX-SERVER_BASE}|${RUN_DIR}|g" \
		| sudo tee /etc/containers/systemd/users/$$(id -u ${RUN_USER})/kiwix-server.container >/dev/null
	sleep 1
	runas systemctl --user daemon-reload

install_cron:
	echo "0 7 * * * ${RUN_USER} cd $$(pwd) && make update 2>&1 | sed \"s|^|\$$(date -Iseconds) |\" >> ${RUN_DIR}/logs/updates.cron.log" \
		| sudo tee /etc/cron.d/kiwix-server_update >/dev/null

update: update_software update_zim_files stop start
install: install_prerequisites install_service install_cron update
uninstall: stop
	$(include_runas)
	sudo rm -rf /etc/containers/systemd/users/$$(id -u ${RUN_USER})
	runas systemctl --user daemon-reload
	sudo loginctl disable-linger ${RUN_USER}
	sleep 1
	sudo userdel --remove ${RUN_USER} 2>/dev/null
	sudo rm -rf ${RUN_DIR}




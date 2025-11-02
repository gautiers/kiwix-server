SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: *
.SILENT:

start:
	DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$${UID}/bus \
	systemctl --user start kiwix-server.service

stop:
	DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$${UID}/bus \
	systemctl --user stop kiwix-server.service

status:
	systemctl --user status kiwix-server.service

update:
	podman pull ghcr.io/kiwix/kiwix-serve

download_wikipedia_fr:
	BASE_URL=https://dumps.wikimedia.org/other/kiwix/zim/wikipedia/; \
	BASE_FILE=wikipedia_fr_all_nopic; \
	LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | sed -r 's/.*href="([^"]+).*/\1/g'); \
	if ! [ -f "./zim_files/$${LATEST}" ]; then \
		wget --directory-prefix=./zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}; \
		rm ./zim_files/$${BASE_FILE}_latest.zim; \
		ln -s $${LATEST} ./zim_files/$${BASE_FILE}_latest.zim; \
	fi;

download_wiktionary_fr:
	BASE_URL=https://dumps.wikimedia.org/other/kiwix/zim/wiktionary/; \
	BASE_FILE=wiktionary_fr_all_nopic; \
	LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | sed -r 's/.*href="([^"]+).*/\1/g'); \
	if ! [ -f "./zim_files/$${LATEST}" ]; then \
		wget --directory-prefix=./zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}; \
		rm ./zim_files/$${BASE_FILE}_latest.zim; \
		ln -s $${LATEST} ./zim_files/$${BASE_FILE}_latest.zim; \
	fi;

download_wikiquote_fr:
	BASE_URL=https://dumps.wikimedia.org/other/kiwix/zim/wikiquote/; \
	BASE_FILE=wikiquote_fr_all_nopic; \
	LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | sed -r 's/.*href="([^"]+).*/\1/g'); \
	if ! [ -f "./zim_files/$${LATEST}" ]; then \
		wget --directory-prefix=./zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}; \
		rm ./zim_files/$${BASE_FILE}_latest.zim; \
		ln -s $${LATEST} ./zim_files/$${BASE_FILE}_latest.zim; \
	fi;

download_wikimed_fr:
	BASE_URL=https://download.kiwix.org/zim/wikipedia/; \
	BASE_FILE=wikipedia_fr_medicine_maxi; \
	LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | sed -r 's/.*href="([^"]+).*/\1/g'); \
	if ! [ -f "./zim_files/$${LATEST}" ]; then \
		wget --directory-prefix=./zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}; \
		rm ./zim_files/$${BASE_FILE}_latest.zim; \
		ln -s $${LATEST} ./zim_files/$${BASE_FILE}_latest.zim; \
	fi;

maintenance: update download_wikipedia_fr download_wiktionary_fr download_wikiquote_fr download_wikimed_fr stop start

install_prerequisites:
	sudo apt install -y wget curl podman

install_service:
	sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $${USER}
	podman system migrate
	sudo mkdir -p /etc/containers/systemd/users/$${UID}
	cat kiwix-server.container.template \
		| sed "s|{KIWIX-SERVER_BASE}|$$(pwd)|g" \
		| sudo tee /etc/containers/systemd/users/$${UID}/kiwix-server.container >/dev/null
	systemctl --user daemon-reload

install_cron:
	echo "0 7 * * * $${USER} cd $$(pwd) && make maintenance 2>&1 | sed \"s|^|\$$(date -Iseconds) |\" >> $$(pwd)/logs/maintenance_cron.log" \
		| sudo tee /etc/cron.d/kiwix-server_maintenance >/dev/null
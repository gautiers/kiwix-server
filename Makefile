SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: *
.SILENT:

start:
	docker compose up -d

stop:
	docker compose down

update:
	docker compose pull

download_wikipedia_fr:
	BASE_URL=https://dumps.wikimedia.org/other/kiwix/zim/wikipedia/; \
	BASE_FILE=wikipedia_fr_all_nopic; \
	LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | cut -d\" -f2); \
	if ! [ -f "./zim_files/$${LATEST}" ]; then \
		wget --directory-prefix=./zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}; \
		rm ./zim_files/$${BASE_FILE}_latest.zim; \
		ln -s $${LATEST} ./zim_files/$${BASE_FILE}_latest.zim; \
	fi;

download_wiktionary_fr:
	BASE_URL=https://dumps.wikimedia.org/other/kiwix/zim/wiktionary/; \
	BASE_FILE=wiktionary_fr_all_nopic; \
	LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | cut -d\" -f2); \
	if ! [ -f "./zim_files/$${LATEST}" ]; then \
		wget --directory-prefix=./zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}; \
		rm ./zim_files/$${BASE_FILE}_latest.zim; \
		ln -s $${LATEST} ./zim_files/$${BASE_FILE}_latest.zim; \
	fi;

maintenance: update download_wikipedia_fr download_wiktionary_fr stop start
SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: *
.SILENT:

download_wikipedia_fr:
	wget \
		--directory-prefix=./zim_files/ \
		--output-file=/dev/null \
		https://dumps.wikimedia.org/other/kiwix/zim/wikipedia/wikipedia_fr_all_nopic_2025-09.zim

download_wiktionary_fr:
	BASE_URL=https://dumps.wikimedia.org/other/kiwix/zim/wiktionary/; \
	BASE_FILE=wiktionary_fr_all_nopic; \
	LATEST=$$(curl --silent $${BASE_URL} | grep $${BASE_FILE} | tail -n 1 | cut -d\" -f2); \
	if ! [ -f "./zim_files/$${LATEST}" ]; then \
		wget --directory-prefix=./zim_files/ --output-file=/dev/null $${BASE_URL}$${LATEST}; \
		ln -s $${LATEST} ./zim_files/$${BASE_FILE}; \
	fi;

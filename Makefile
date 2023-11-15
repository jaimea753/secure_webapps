.DEFAULT_GOAL := install

PREFIX = /usr/local
INSTALL = $(PREFIX)/bin
FILE = secure_webapps

install:
	install -m755 $(FILE).sh $(INSTALL)/$(FILE)

uninstall: 
	rm -rf $(INSTALL)/$(FILE)

.PHONY: install uninstall

################################################################### 
# Installation diffplist tool
#
# See also: https://github.com/humangas/diffplist
################################################################### 
.DEFAULT_GOAL := help

.PHONY: all help install update

all:

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "target:"
	@echo " - install:   \"difp\" command becomes available"
	@echo " - update:    Update dotfiles repository"
	@echo ""

install:
	@chmod u+x $(PWD)/diffplist.sh
	@rm -f /usr/local/bin/diffp
	@ln -s $(PWD)/diffplist.sh /usr/local/bin/diffp
	
update:
	@git pull origin master

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
	@chmod u+x $(PWD)/difp.sh
	@rm -f $(HOME)/bin/difp
	@ln -s $(PWD)/difp.sh $(HOME)/bin/difp
	
update:
	@git pull origin master

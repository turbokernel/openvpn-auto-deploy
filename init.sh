#!/usr/bin/env bash

source ./common/def.sh
source ./common/functions.sh

case "${1}" in
	install)
		php_install
		;;
	remove)
		php_install 1
		;;

#	ext)
#
#		;;
	*)
		echo "Usage: ./init.sh {install|remove}"
		;;
esac

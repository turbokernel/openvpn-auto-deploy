#!/usr/bin/env bash

source ./def.sh


install_openvpn_pkg() {
	apt-get install ${OPENVPN_REQUIRE_PKGS} -y
	if [[ $? -eq 0 ]]; then
		echo "Install Packages Success!"
	else
		echo "Install Packages Fail!"
		exit 1
	fi
}

setup_ca() {
	#Create CA Directory
	if [[ ! -e ${CA_DIRECTORY} ]]; then
		make-cadir ${CA_DIRECTORY}
		if [[ $? -eq 0 ]]; then
			echo "Create CA Directory Success!"
		else
			echo "Create CA Directory Fail!"
			exit 1
		fi
#	else
#		echo "${CA_DIRECTORY} Exits,empty the directory or exit the script,make your choice:"
#		echo "1)EEMPTY THE DIERCTORY!!	2)Exit"
#		read $choice
#		case $choice in
#			1 )
#				rm -rf ${CA_DIRECTORY}
#				echo "${CA_DIRECTORY} emptied!"
#				;;
#			2 )
#				exit 0
#				;;
#
#		esac
	fi
	#modify vars config file
	if [[ -e ${CA_DIRECTORY}/vars ]]; then
		sed -i s/"^KEY_COUNTRY.*\"$"/KEY_COUNTRY=\"${KEY_COUNTRY}\"/g ${CA_DIRECTORY}/var
		sed -i s/"^KEY_PROVINCE.*\"$"/KEY_PROVINCE=\"${KEY_PROVINCE}\"/g ${CA_DIRECTORY}/var
		sed -i s/"^KEY_CITY.*\"$"/KEY_CITY=\"${KEY_CITY}\"/g ${CA_DIRECTORY}/var
		sed -i s/"^KEY_ORG.*\"$"/KEY_ORG=\"${KEY_ORG}\"/g ${CA_DIRECTORY}/var
		sed -i s/"^KEY_EMAIL.*\"$"/KEY_EMAIL=\"${KEY_EMAIL}\"/g ${CA_DIRECTORY}/var
		sed -i s/"^KEY_OU.*\"$"/KEY_OU=\"${KEY_OU}\"/g ${CA_DIRECTORY}/var
		sed -i s/"^KEY_NAME.*\"$"/KEY_NAME=\"${KEY_NAME}\"/g ${CA_DIRECTORY}/var
	fi
	cd ${CA_DIRECTORY}
	source ${CA_DIRECTORY}/vars
	${CA_DIRECTORY}/clean-all
	${CA_DIRECTORY}/build-ca <<EOF







EOF

}

#*****************************
#*	FOR COMMON FUNCTION		*
#*****************************

config_modify() {
	if [[ -e $1 ]]; then
		if [[ ! $2 -eq null ]]; then
			echo "key and value are givened!"
		else
			echo "#2 is $2"
			echo "#3 is $3"
		fi
	else
		echo "Config File $1 Do Not Exits!!"
		touch $1
	fi
}
sys_ctl() {
	echo ""
}
config_modify file1 key value
#
install_openvpn() {
	echo "Installing PKG..."
	install_openvpn_pkg
}

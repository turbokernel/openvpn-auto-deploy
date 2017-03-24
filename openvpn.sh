#!/bin/bash
#Auth:Sam.Ma
########################################################################################
############################
########Vars Definition#####
############################
#Global defination
export MY_SERVER_NAME='openvpn'
export CLIENTS='client1 client2 client3 client4'
export CA_DIRECTORY='~/openvpn-ca'
#Key Setting
export KEY_COUNTRY='CN'
export KEY_PROVINCE='GD'
export KEY_CITY='GuangZhou'
export KEY_ORG='MediaClick'
export KEY_EMAIL='admin@gzmediaclick.com'
export KEY_OU='TechDep'
export KEY_NAME='server'
#Public interface name
export PUB_ETH=`ip route | grep default | awk '{print $5}'`
#Vpn serverconfig-file
export VPN_SERVER_ADDRESS='****'
export VPN_SERVER_TYPE='tcp'
export VPN_SERVER_PORT='443'
#Make_config function vars
export KEY_DIR='~/openvpn-ca/keys'
export OUTPUT_DIR='~/client-configs/files'
export BASE_CONFIG='~/client-configs/base.conf'
CURRENT_DIR=`pwd`
#########################
###Function Definition###
#########################
make_config() {
	cat ${BASE_CONFIG} 
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${1}.ovpn
}
########################################################################################
#Install OpenVPN

apt-get update
apt-get install openvpn easy-rsa -y

#Set Up the CA Directory

make-cadir ~/openvpn-ca

#Configure the CA Variables

cd ~/openvpn-ca

####edit the vars

sed -i s/"KEY_COUNTRY.*\"$"/KEY_COUNTRY=\"${KEY_COUNTRY}\"/g vars
sed -i s/"KEY_PROVINCE.*\"$"/KEY_PROVINCE=\"${KEY_PROVINCE}\"/g vars
sed -i s/"KEY_CITY.*\"$"/KEY_CITY=\"${KEY_CITY}\"/g vars
sed -i s/"KEY_ORG.*\"$"/KEY_ORG=\"${KEY_ORG}\"/g vars
sed -i s/"KEY_EMAIL.*\"$"/KEY_EMAIL=\"${KEY_EMAIL}\"/g vars
sed -i s/"KEY_OU.*\"$"/KEY_OU=\"${KEY_OU}\"/g vars
sed -i s/"KEY_NAME.*\"$"/KEY_NAME=\"${KEY_NAME}\"/g vars

#Build the Certificate Authority
#修改build-ca,build-key-server,build-key去掉--interact,变为自动化模式,修改前备份文件
#
cp /usr/share/easy-rsa/build-ca /usr/share/easy-rsa/build-ca.default
sed -i s/--interact//g build-ca
cp /usr/share/easy-rsa/build-key-server /usr/share/easy-rsa/build-key-server.default
sed -i s/--interact//g build-key-server
cp /usr/share/easy-rsa/build-key /usr/share/easy-rsa/build-key.default
sed -i s/--interact//g build-key

#
source vars
./clean-all
./build-ca 
#Create the Server Certificate, Key, and Encryption Files

./build-key-server ${MY_SERVER_NAME}
./build-dh
openvpn --genkey --secret keys/ta.key

#Configure the OpenVPN Service

cd ~/openvpn-ca/keys
cp ca.crt ca.key ${MY_SERVER_NAME}.crt ${MY_SERVER_NAME}.key ta.key dh2048.pem /etc/openvpn
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf


##Modify OpenVPN Config File
cp /etc/openvpn/server.conf /etc/openvpn/server.conf.default
sed -i s/^\;tls/tls/g /etc/openvpn/server.conf
echo '#New Config' >> /etc/openvpn/server.conf
echo 'key-direction 0' >> /etc/openvpn/server.conf
sed -i s/^\;cipher[[:space:]]AES/cipher\ AES/g /etc/openvpn/server.conf
echo "auth SHA256" >> /etc/openvpn/server.conf
sed -i s/^\;user/user/g /etc/openvpn/server.conf
sed -i s/^\;group/group/g /etc/openvpn/server.conf
sed -i s/^\;push\ \"redirect-gateway/push\ \"redirect-gateway/g /etc/openvpn/server.conf
sed -i s/^\;push\ \"dhcp-option/push\ \"dhcp-option/g /etc/openvpn/server.conf
sed -i s/^port.*/port\ 443/g /etc/openvpn/server.conf
sed -i s/^proto.*/proto\ tcp/g /etc/openvpn/server.conf
sed -i s/^cert.*/cert\ ${MY_SERVER_NAME}.crt/g /etc/openvpn/server.conf
sed -i s/^key[[:space:]].*/key\ ${MY_SERVER_NAME}.key/g /etc/openvpn/server.conf
cp /etc/openvpn/server.conf /etc/openvpn/${MY_SERVER_NAME}.conf
##Modify sysctl.conf
sed -i s/^#net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g /etc/sysctl.conf
##Apply sysctl.conf
sysctl -p

##Firewall rules

sed -i '11i# END OPENVPN RULES' /etc/ufw/before.rules
sed -i '11iCOMMIT' /etc/ufw/before.rules
sed -i 11i-A\ POSTROUTING\ -s\ 10.8.0.0/8\ -o\ ${PUB_ETH}\ -j\ MASQUERADE /etc/ufw/before.rules
sed -i '11i# Allow traffic from OpenVPN client to server' /etc/ufw/before.rules
sed -i '11i:POSTROUTING ACCEPT [0:0]' /etc/ufw/before.rules
sed -i '11i*nat' /etc/ufw/before.rules
sed -i '11i# NAT table rules' /etc/ufw/before.rules
sed -i '11i# START OPENVPN RULES' /etc/ufw/before.rules

##Apply firewall rules

ufw allow 443/tcp
ufw allow OpenSSH
ufw disable
yes | ufw enable

#Start and Enable the OpenVPN Service
systemctl start openvpn@${MY_SERVER_NAME}
systemctl status openvpn@${MY_SERVER_NAME} | grep Active
if [[ $? -eq 0 ]]; then
	echo "Openvpn active (running)"
fi
systemctl enable openvpn@${MY_SERVER_NAME}

##Create Client Configuration Infrastructure

mkdir -p ~/client-configs/files
chmod 700 ~/client-configs/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf


####edit ~/client-configs/base.conf
sed -i s/^remote[[:space:]].*/remote\ ${VPN_SERVER_ADDRESS}\ 443/g ~/client-configs/base.conf
sed -i s/^proto.*/proto\ tcp/g ~/client-configs/base.conf
sed -i s/^\;user/user/g ~/client-configs/base.conf
sed -i s/^\;group/group/g ~/client-configs/base.conf
sed -i s/^ca[[:space:]]/#ca\ /g ~/client-configs/base.conf
sed -i s/^cert[[:space:]]/#cert\ /g ~/client-configs/base.conf
sed -i s/^key[[:space:]]/#key\ /g ~/client-configs/base.conf
echo 'cipher AES-128-CBC' >> ~/client-configs/base.conf
echo 'auth SHA256' >> ~/client-configs/base.conf
echo 'key-direction 1' >> ~/client-configs/base.conf

#Generate a Client Certificate and Key Pair
for i in ${CLIENTS}; do
	cd ~/openvpn-ca
	source vars
	./build-key ${i}
done

#Generate Client Configurations
cd ../..
for i in ${CLIENTS}; do
	cd ~/
	./make_config.sh $i
done

echo "Client Configurations is in ~/client-configs/files"



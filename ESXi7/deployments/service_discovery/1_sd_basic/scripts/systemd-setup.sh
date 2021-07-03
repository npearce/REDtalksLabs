#!/bin/sh

#################################
#         Mint configs          #
#################################

#mkdir /usr/local/rtlab
#chown debian:debian /usr/local/rtlab
#cd /usr/local/rtlab/
#git clone https://github.com/REDtalksLive/rtlab-configs.git #TODO: Lets build this with tpl
#mv bin/rtlab-env.sh /usr/local/bin/
#chwon debian /usr/local/bin/rtlab-env.sh
#/usr/local/bin/rtlab-env.sh $1 $2


#################################
#         Setup SystemD         #
#################################

echo "enabling $1 service"

if [ $1 = "consul" ]
then

echo "enabling consul service"
#Create Systemd Config for Consul
cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target

[Service]
User=consul
Group=consul
ExecStart=/usr/bin/consul agent  -bind '{{ GetInterfaceIP "ens160" }}' -config-dir=/etc/consul.d/
ExecReload=/usr/bin/consul reload
KillMode=process
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

#Enable the service
systemctl enable consul
service consul start

fi
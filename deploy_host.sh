#!/bin/bash

virsh net-destroy default
virsh net-undefine default

virsh pool-undefine default
virsh pool-destroy default
virsh pool-define-as default --type dir --target /home/scorpio/hdd
virsh pool-autostart default
virsh pool-start default

source /etc/sysconfig/network-scripts/ifcfg-$(ip route | grep default|awk '{print $5;exit}')
echo "DEVICE=br$counter" >> /etc/sysconfig/network-scripts/ifcfg-br$counter
echo "TYPE=Bridge" >> /etc/sysconfig/network-scripts/ifcfg-br$counter
echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-br$counter
echo "BOOTPROTO=$BOOTPROTO" >> /etc/sysconfig/network-scripts/ifcfg-br$counter
if [ "$BOOTPROTO" == "none" ]
then
echo "IPADDR=$IPADDR" >> /etc/sysconfig/network-scripts/ifcfg-br$counter
echo "NETMASK=$NETMASK" >> /etc/sysconfig/network-scripts/ifcfg-br$counter
sed -i -e '/^IPADDR/ d' /etc/sysconfig/network-scripts/ifcfg-$i
sed -i -e '/^NETMASK/ d' /etc/sysconfig/network-scripts/ifcfg-$i
sed -i -e '/^BOOTPROTO/ d' /etc/sysconfig/network-scripts/ifcfg-$i
fi
if [ ! -z "$SCOPE" ]
then                                                                                                                                                                                                                                                                           
echo "SCOPE=\"$SCOPE\"" >> /etc/sysconfig/network-scripts/ifcfg-br$counter
sed -i -e '/^SCOPE/ d' /etc/sysconfig/network-scripts/ifcfg-$i
fi
if [ ! -z "$GATEWAY" ]
then
echo "GATEWAY=$GATEWAY" >> /etc/sysconfig/network-scripts/ifcfg-br$counter
sed -i -e '/^GATEWAY/ d' /etc/sysconfig/network-scripts/ifcfg-$i
fi
echo "BRIDGE=br$counter" >> /etc/sysconfig/network-scripts/ifcfg-$i

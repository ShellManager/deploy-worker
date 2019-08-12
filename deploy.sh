#!/usr/bin/env bash
if [[ ! -z "$1" && ! -z "$2" && ! -z "$3" ]]
  then
    mv $1.xml /etc/libvirt/qemu/
    qemu-img create -f qcow2 $2/$1.qcow2 $3
    virsh define /etc/libvirt/qemu/$1.xml
    virsh start $1
else
    echo "Usage: $0 domain_to_define location_to_save size_of_disk"
    exit 1
fi

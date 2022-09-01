#!/bin/bash

# Example gitpkg:
# ./run-full.sh https://gitpkg.now.sh/hashintel/hash/packages/blocks/callout\?main

readonly kernel_path=$(pwd)"/../vmlinux510.bin"
readonly rootfs_path=$(pwd)"/rootfs.img"
readonly iface="eth0"
readonly tap="tap0"
readonly socket_path=/tmp/firecracker.socket

firecracker --api-sock $socket_path &

readonly firecracker_ps=$!

sleep 1

curl --unix-socket $socket_path -i \
  -X PUT 'http://localhost/boot-source'   \
  -H 'Accept: application/json'           \
  -H 'Content-Type: application/json'     \
  -d "{
        \"kernel_image_path\": \"${kernel_path}\",
        \"boot_args\": \"console=ttyS0 reboot=k panic=1 pci=off init=/init-agent ip=10.0.0.3::10.0.0.1:255.255.255.0::eth0:off\"
    }"


curl --unix-socket $socket_path -i \
  -X PUT 'http://localhost/drives/rootfs' \
  -H 'Accept: application/json'           \
  -H 'Content-Type: application/json'     \
  -d "{
        \"drive_id\": \"rootfs\",
        \"path_on_host\": \"${rootfs_path}\",
        \"is_root_device\": true,
        \"is_read_only\": false
   }"

curl --unix-socket $socket_path -i  \
  -X PUT 'http://localhost/machine-config' \
  -H 'Accept: application/json'            \
  -H 'Content-Type: application/json'      \
  -d '{
      "vcpu_count": 2,
      "mem_size_mib": 1024
  }'


curl --unix-socket $socket_path -i \
  -X PUT "http://localhost/network-interfaces/$iface" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{
        \"iface_id\": \"$iface\",
        \"guest_mac\": \"AA:FC:00:00:00:01\",
        \"host_dev_name\": \"$tap\"
    }"

curl --unix-socket $socket_path -i \
    -X PUT "http://localhost/mmds/config"     \
    -H "Content-Type: application/json"       \
    -d "{
          \"network_interfaces\": [\"$iface\"],
          \"version\": \"V1\",
          \"ipv4_address\": \"169.254.170.2\"
    }"

curl --unix-socket $socket_path -i \
    -X PUT "http://localhost/mmds"            \
    -H "Content-Type: application/json"       \
    -d "{
            \"gitpkg\": \"$1\"
    }"


curl --unix-socket $socket_path -i \
  -X PUT 'http://localhost/actions'       \
  -H  'Accept: application/json'          \
  -H  'Content-Type: application/json'    \
  -d '{
      "action_type": "InstanceStart"
   }'

fg %1

wait $firecracker_ps

temp_mount=$(mktemp -d)

sudo mount ./rootfs.img "$temp_mount"

if [ -f "$temp_mount/home/node/out.tgz" ]; then
    echo "$FILE exists."
    cp "$temp_mount/home/node/out.tgz" "$(pwd)" 
    tar -tvf out.tgz
fi

sudo umount "$temp_mount"

rm -f $socket_path
rm -fr "$temp_mount"

# curl --unix-socket /tmp/firecracker.socket -i \
#    -X PUT "http://localhost/actions" \
#    -H  "accept: application/json" \
#    -H  "Content-Type: application/json" \
#    -d "{
#             \"action_type\": \"SendCtrlAltDel\"
#    }"
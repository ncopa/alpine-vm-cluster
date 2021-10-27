#!/bin/sh

set -e
: ${nameserver:=192.168.122.1}
: ${user:=root}
: ${port:=22}
: ${keyPath:="$HOME/.ssh/id_ed25519"}

getaddr() {
	local host="$1" addr addrlist
	for i in $(seq 0 120); do
#		addrlist=$(virsh --connect=qemu:///system net-dhcp-leases default | awk -v host="$1" '$6 == host {print $5}')
#		for addr in $addrlist; do
#			echo "Probing $1 ($addr)" >&2
#			if ping -c1 ${addr%/*} >/dev/null; then
#				echo ${addr%/*}
#				return
#			fi
#		done
		addr=$(dig "$host" "@$nameserver" | awk '$4 == "A" {print $5}')
		if [ -n "$addr" ] && ping -c 1 $addr >/dev/null; then
			echo "$addr" && return
		fi
		sleep 1s
	done
	return 1
}

cat <<EOF
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
spec:
  hosts:
EOF

for host; do
	echo "#host: $host"
	address=$(getaddr "$host")
	case "$host" in
		*controller*) role=controller;;
		*worker*) role=worker;;
	esac
	cat <<EOF	
  - ssh:
      address: $address
      port: $port 
      user: $user
      keyPath: $keyPath
    role: $role
EOF
	sed -i -e "/$host/d" ~/.ssh/known_hosts
done

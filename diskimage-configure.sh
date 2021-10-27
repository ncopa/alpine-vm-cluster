#!/bin/sh

_step_counter=0
step() {
	_step_counter=$(( _step_counter + 1 ))
	printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}

step 'Set up networking'
cat > /etc/network/interfaces <<-EOF
	iface lo inet loopback

	auto eth0
	iface eth0 inet dhcp
		hostname \$(hostname)
EOF

step 'Set up cloud-alpinit-local'
cat > /etc/init.d/cloud-alpinit-local <<EOF
#!/sbin/openrc-run

description="Set hostname from cloud-init meta-data if found"

depend() {
	keyword -prefix -docker
	before net hostname
	after root
}

start() {
	local cidata_dev=\$(findfs LABEL=cidata) local_hostname
	if [ -z "\$cidata_dev" ]; then
		return 0
	fi
	ebegin "Reading cloud-alpinit meta data from \$cidata_dev"
	(
		eval \$(blkid -o export "\$cidata_dev")
		mkdir -p /run/cidata
		mount -t \$TYPE \$cidata_dev /run/cidata
	)
	eend \$?
	if [ -f /run/cidata/meta-data ]; then
		local_hostname=\$(awk -F':\\s*' '\$1 == "local-hostname" {print \$2}' < /run/cidata/meta-data)
		if [ -n "\$local_hostname" ]; then
			ebegin "Setting hostname from meta_data: \$local_hostname"
			printf "%s\n" "\$local_hostname" > /etc/hostname
			eend \$?
		fi
	fi
	umount /run/cidata
}
EOF
chmod +x /etc/init.d/cloud-alpinit-local

step 'Adjust boot timeout'
sed -Ei \
	-e 's/^timeout=.*/timeout=1/' \
	/etc/update-extlinux.conf
update-extlinux

step 'Enable services'
rc-update add cgroups boot
rc-update add machine-id boot
rc-update add cloud-alpinit-local boot
rc-update add networking boot

rc-update add acpid default
rc-update add crond default
rc-update add sshd default

if [ -n "$1" ]; then
	step 'Adding ssh keys for root'
	mkdir -p /root/.ssh
	echo "$1"  > /root/.ssh/authorized_keys
fi


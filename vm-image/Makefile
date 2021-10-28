
alpine_branch=v3.14
image_format=qcow2
images_size=10G
kernel_flavor=virt
packages=openssh-server e2fsprogs dhcpcd
keypath=$(HOME)/.ssh/id_ed25519

DOAS=doas

alpine-cloud.img: diskimage-configure.sh repositories
	$(DOAS) alpine-make-vm-image --branch $(alpine_branch) \
		--image-format $(image_format) \
		--image-size $(images_size) \
		--kernel-flavor $(kernel_flavor) \
		--packages "$(packages)" \
		--script-chroot \
		-- \
		$@.tmp \
		./diskimage-configure.sh "$(shell cat $(keypath).pub)"
	$(DOAS) chown $(shell id -u):$(shell id -g) $@.tmp
	mv $@.tmp $@

repositories:
	printf "%s\n%s\n" \
		"https://dl-cdn.alpinelinux.org/alpine/$(alpine_branch)/main" \
		"https://dl-cdn.alpinelinux.org/alpine/$(alpine_branch)/community" > $@


.PHONY: clean
clean:
	rm -f alpine-cloud.img meta-data seed.iso repositories

# those are only for debugging purposes
seed.iso: meta-data
	genisoimage -output $@ -volid cidata -joliet -rock $<

meta-data:
	echo "local-hostname: myhost" > $@


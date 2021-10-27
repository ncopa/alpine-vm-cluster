
alpine_branch=v3.14
image_format=qcow2
images_size=10G
kernel_flavor=virt
packages=openssh-server e2fsprogs
keypath=$(HOME)/.ssh/id_ed25519

DOAS=doas
k0sctl ?= k0sctl

kubeconfig: k0sctl.yaml
	$(k0sctl) apply
	$(k0sctl) kubeconfig > $@.tmp
	mv $@.tmp $@
	@echo "export KUBECONFIG=$$PWD/$@"

k0sctl.yaml: nodelist.txt
	sh generate-k0sctl.sh $$(cat nodelist.txt ) > $@.tmp
	mv $@.tmp $@

nodelist.txt: variables.tf libvirt.tf providers.tf meta-data alpine-cloud.img
	terraform apply -auto-approve

meta-data:
	echo "local-hostname: \$${hostname}" > $@

alpine-cloud.img: configure.sh repositories
	$(DOAS) alpine-make-vm-image --branch $(alpine_branch) \
		--image-format $(image_format) \
		--image-size $(images_size) \
		--kernel-flavor $(kernel_flavor) \
		--packages "$(packages)" \
		--script-chroot \
		-- \
		$@.tmp \
		./configure.sh "$(shell cat $(keypath).pub)"
	$(DOAS) chown $(shell id -u):$(shell id -g) $@.tmp
	mv $@.tmp $@

repositories:
	printf "%s\n%s\n" \
		"https://dl-cdn.alpinelinux.org/alpine/$(alpine_branch)/main" \
		"https://dl-cdn.alpinelinux.org/alpine/$(alpine_branch)/community" > $@

.PHONY: clean
clean: meta-data
	terraform destroy
	rm -f nodelist.txt k0sctl.yaml kubeconfig

.PHONY: clean-all
clean-all: clean
	rm -f alpine-cloud.img meta-data seed.iso

# those are only for debugging purposes
seed.iso: meta-data
	genisoimage -output $@ -volid cidata -joliet -rock $<



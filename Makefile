k0sctl ?= k0sctl

kubeconfig: k0sctl.yaml
	$(k0sctl) apply
	$(k0sctl) kubeconfig > $@.tmp
	mv $@.tmp $@
	@echo "export KUBECONFIG=$$PWD/$@"

k0sctl.yaml: nodelist.txt
	sh generate-k0sctl.sh $$(cat nodelist.txt ) > $@.tmp
	mv $@.tmp $@

nodelist.txt: variables.tf libvirt.tf providers.tf meta-data vm-image/alpine-cloud.img
	terraform apply -auto-approve

meta-data:
	echo "local-hostname: \$${hostname}" > $@

vm-image/alpine-cloud.img:
	$(MAKE) -C vm-image alpine-cloud.img

.PHONY: clean
clean: meta-data
	terraform destroy
	rm -f nodelist.txt k0sctl.yaml kubeconfig

.PHONY: clean-all
clean-all: clean
	$(MAKE) -C vm-image clean

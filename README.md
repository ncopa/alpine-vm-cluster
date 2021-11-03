# alpine k0s cluster with terraform and libvirt

My development cluster with libvirt and terraform

## Prerequisites

- libvirt with qemu
- terraform
- terraform-provider-libvirt
- alpine-make-vm-image
- k0sctl

alpine-make-vm-image needs root permissions. Currently `doas` is used for this.

User should be in `libvirt` group.

The libvirt network `default` is used. It is assumed that the DNS server
for this is listening on 192.168.122.1.

The ssh key `$HOME/.ssh/id_ed25519` is used for root logins. If this is
password protected you should add the key with:
```
eval $(ssh-add ~/.ssh/id_ed25519)
```

## How to configure the cluster

The file `variables.tf` has some variables for the cluster:

- memory: amount of RAM (in megabytes) for ach virtual machine.
- vcpu: number of virtual CPUs for each virtual machine.
- controller_nodes: number of controllers in the kubernetes cluster
- worker_nodes: number of workers for the controller node

## How to build the cluster

Run `make`. This will:

1) build vm-image/alpine-cloud.img
2) use `terraform apply` to spin up the virtual machines and feed them
   with a seed.iso image with cloud-init config (currently only hostname is set)
3) generate a `nodelist.txt` with the list of virtual machines hostnames
4) use `dig` to query the 192.168.122.1 DNS server for the ip address of
   the virtual machines.
5) generate a `k0sctl.yaml` config with the list of IP addresses.
6) execute `k0sctl` to spin up the cluster
7) generate a `kubeconfig` file for `kubectl` or Lens.

## How to connect to the kubernetes cluster

To use the generated `kubeconfig` run:
```
export KUBECONFIG=$PWD/kubeconfig
```

Now you can connect to the cluster with `kubectl`:
```
kubectl get nodes
```


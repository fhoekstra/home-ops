# kubernetes-rock5t

Second, single-node Talos cluster on a Radxa Rock 5T Plus, managed with
talstomize (see [../README.md](../README.md)).

## Before first apply (TODOs)

- [ ] `talstomize.yaml`, `patches/talos-rock5t-1/disk.yaml` and
      `patches/talos-rock5t-1/network.yaml`: real endpoint/VIP, node IP, NIC
      MAC (`talosctl get link --insecure -n <IP> -o yaml`) and boot media
      device (`talosctl disks --insecure -n <IP>`)
- [ ] Decide on data disks: add `VolumeConfig` patches (see
      `../kubernetes/patches/talos-rock-1/disk.yaml` for the EPHEMERAL
      pattern) and/or `RawVolumeConfig`s
- [ ] Storage workloads: the ZFS and NFS server extensions are baked into
      the installer schematic in `talstomize.yaml`; add kubelet mounts / CSI
      config once the workloads are chosen
- [ ] Boot the node into Talos maintenance mode, then:

      task bootstrap:talos CLUSTER=kubernetes-rock5t

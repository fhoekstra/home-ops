# kubernetes-rock5t

Second, single-node Talos cluster on a Radxa Rock 5T Plus, managed with topf.

This directory is self-contained: `topf.yaml`, its own `secrets.sops.yaml` and
schematic, plus patches specific to this cluster. The common baseline lives in
[`../shared/patches`](../shared/patches) and is wired in via `00-shared`
symlinks (see [../README.md](../README.md)). topf manages one cluster per
invocation, so each cluster gets its own directory and is selected with
`CLUSTER=<name>` on every task, e.g.:

    task talos:render CLUSTER=kubernetes-rock5t
    task bootstrap:talos CLUSTER=kubernetes-rock5t

## Before first apply (TODOs)

- [ ] `topf.yaml`, `patches/control-plane/11-install-disk.yaml` and
      `patches/node/talos-rock5t-1/01-link.yaml`: real endpoint/VIP, node IP,
      NIC MAC (`talosctl get link --insecure -n <IP> -o yaml`) and boot media
      device (`talosctl disks --insecure -n <IP>`)
- [ ] Decide on data disks: add `VolumeConfig` patches (see
      `../kubernetes/patches/node/talos-rock-1/01-volume-ephemeral.yaml` for
      the EPHEMERAL pattern) and/or `RawVolumeConfig`s
- [ ] Storage workloads: the ZFS and NFS server extensions are baked into the
      schematic; add kubelet mounts / CSI config once the workloads are chosen
- [ ] Boot the node into Talos maintenance mode, then:

      task bootstrap:talos CLUSTER=kubernetes-rock5t

The schematic (`schematic-rock-5t-plus.yaml`) is already registered with the
Talos image factory as
`ad1e013b446245bed31c54c06f99c77d48a05b0f4ddce9759af25f9445f0ac6b`, so no
`--submit-to-factory` run is needed.

## Flux

The Flux side (`kubernetes/flux/cluster`) still only targets the original
`kubernetes` cluster; wiring this cluster into Flux is not done yet.

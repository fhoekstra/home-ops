# kubernetes-rock5t

Second Talos cluster on Radxa Rock 5T Plus boards, managed with topf.

This directory is self-contained: `topf.yaml`, its own `secrets.sops.yaml`,
schematic and patch tree. topf manages one cluster per invocation, so each
cluster gets its own directory and is selected with `CLUSTER=<name>` on every
task, e.g.:

    task talos:render CLUSTER=kubernetes-rock5t
    task bootstrap:talos CLUSTER=kubernetes-rock5t

## Before first apply (TODOs)

- [ ] `topf.yaml`: real cluster endpoint + node IPs
- [ ] `patches/node/talos-rock5t-*/03-link-alias.yaml`: real NIC MACs
      (`talosctl get link --insecure -n <IP> -o yaml`)
- [ ] `patches/node/talos-rock5t-*/02-install-disk.yaml`: verify the boot
      media device (`talosctl disks --insecure -n <IP>`)
- [ ] Decide on data disks: add `VolumeConfig` patches (see
      `../kubernetes/patches/node/talos-rock-1/03-volume-ephemeral.yaml`
      for the EPHEMERAL pattern) and/or RawVolumeConfigs
- [ ] Boot the nodes into Talos maintenance mode, then:

      topf apply --auto-bootstrap          # or: task bootstrap:talos CLUSTER=kubernetes-rock5t

The schematic (`schematic-rock-5t-plus.yaml`, ZFS + NFS server + rockchip
extensions) is already registered with the Talos image factory as
`ad1e013b446245bed31c54c06f99c77d48a05b0f4ddce9759af25f9445f0ac6b`, so no
`--submit-to-factory` run is needed.

## Flux

The Flux side (`kubernetes/flux/cluster`) still only targets the original
`kubernetes` cluster; wiring this cluster into Flux is not done yet.

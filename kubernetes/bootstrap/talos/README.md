# Talos clusters

This directory holds the Talos machine configuration for every cluster, managed with [talstomize](https://github.com/mirceanton/talstomize).

## Layout

Each subdirectory is one cluster, named after its `clusterName`. Every cluster
is self-contained: its own `talstomize.yaml`, `talos-secrets.sops.yaml`, and
`patches/` directory for anything specific to it.

| Directory | Cluster | Nodes |
| --------- | ------- | ----- |
| [`kubernetes/`](./kubernetes) | `kubernetes` | 3x Rock 5B+ controlplane |
| [`kubernetes-rock5t/`](./kubernetes-rock5t) | `kubernetes-rock5t` | 1x Rock 5T Plus controlplane |

Every task takes a `CLUSTER=<name>` argument (defaults to `kubernetes`):

    task talos:generate-config
    task talos:generate-config CLUSTER=kubernetes-rock5t

## Sharing config

Patches that apply to every cluster live in [`patches/`](./patches) and are
referenced from each cluster's `talstomize.yaml` with relative paths:

- `../patches/...` — shared by every cluster
- `./patches/...` — this cluster only

Patches are applied in the order they are listed in `talstomize.yaml`, with
later patches overriding earlier ones: shared `all` patches first, then the
cluster's own, then role patches (`controlplanePatches`/`workerPatches`),
then per-node patches.

To add a cluster, copy an existing cluster directory, adjust
`clusterName`/`controlPlaneEndpoint`/nodes/patches, and generate a fresh
secrets bundle (`talosctl gen secrets -o talos-secrets.sops.yaml` + `sops
--encrypt --in-place talos-secrets.sops.yaml`).

# Talos clusters

This directory holds the Talos machine configuration for every cluster, managed with [topf](https://postfinance.github.io/topf).

## Layout

Each subdirectory (except `shared/`) is one cluster, named after its `clusterName`. Every cluster has its own `topf.yaml`, `secrets.sops.yaml`, schematic, and `patches/` directory for anything specific to it.

| Directory | Cluster | Nodes |
| --------- | ------- | ----- |
| [`kubernetes/`](./kubernetes) | `kubernetes` | 3x Rock 5B+ controlplane |
| [`kubernetes-rock5t/`](./kubernetes-rock5t) | `kubernetes-rock5t` | 1x Rock 5T Plus controlplane |

Every task takes a `CLUSTER=<name>` argument (defaults to `kubernetes`):

    task talos:render
    task talos:render CLUSTER=kubernetes-rock5t

## Sharing config

Patches that apply to every cluster live in [`shared/patches/`](./shared/patches). Each cluster references them with a `00-shared` symlink inside its own `patches/all/` and `patches/control-plane/` — topf walks symlinked directories, and `00-` sorts before the cluster-specific files, so the shared baseline is applied first and cluster patches (numbered `10+`) override it.

topf manages one cluster per invocation, so there is nothing to share at the `topf.yaml` level: cluster identity, nodes, and schematic live in each cluster's own directory.

To add a cluster, copy an existing cluster directory, adjust `clusterName`/`clusterEndpoint`/nodes/`schematicId`, keep the `00-shared` symlinks, and generate a fresh secrets bundle (`topf secrets` + `sops --encrypt --in-place secrets.sops.yaml`).

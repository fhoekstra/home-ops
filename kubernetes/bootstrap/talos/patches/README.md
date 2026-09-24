# Shared Talos patches

Patches here are shared by every cluster: each cluster's `talstomize.yaml`
references them with relative paths like `../patches/all/machine-kubelet.yaml`.

<https://www.talos.dev/v1.13/talos-guides/configuration/patching/>

## Patch Directories

- `all/`: applied to every node of every cluster
- `controlplane/`: applied to every controlplane node of every cluster
- `unused/`: currently disabled patches. To enable one, move it into `all/`
  or `controlplane/` and reference it from the clusters that need it.

Cluster-specific patches live in each cluster's own `patches/` directory (see [../README.md](../README.md)).

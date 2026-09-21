# Talos Patching

This directory contains Talos machine config patches that are referenced from the talstomize configuration file.

<https://www.talos.dev/v1.13/talos-guides/configuration/patching/>

## Patch Directories

Under this `patches` directory, there are several sub-directories that can contain patches that are referenced from the talstomize configuration file.
Each directory is optional and therefore might not created by default.

- `global/`: patches that are applied to every node, regardless of role
- `controlplane/`: patches that are applied to every controlplane node
- `${node-name}/`: patches that are applied to the node with the specified name

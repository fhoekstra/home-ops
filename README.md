# My Home Ops repo

Self-hosting and managing your setup through GitOps.
That is the journey I've started, using [@onedr0p](https://github.com/onedr0p)'s excellent [cluster template](https://github.com/onedr0p/cluster-template).

This repo uses [Talos Linux](https://www.talos.dev/) and [Flux](https://fluxcd.io/) to fully declaratively manage a Kubernetes cluster at home.

# Hardware

> [!NOTE]
> For an in-depth write-up of my current homelab hardware, check out my [blog at **fhoekstra.eu**](https://fhoekstra.eu/posts/the-kube-the-smallest-enterprise-home-lab/)


<img width="4640" height="3472" alt="3_kubes_finished" src="https://github.com/user-attachments/assets/61a5f19d-5e53-44cb-84ee-7eaed92830e9" />

<br/>

| Role | Model | CPU | RAM | SSD |
| ------------- | ------------- | -------------- | -------------- |-------|
| K8s controlplane, k8s workloads | `kube` (Rock 5B+) | RK3588 (4x A76 + 4x A55) | 24GB LPDDR5 | 32GB microSD for read-only root and boot, PLP SSDs for [Talos](./kubernetes/bootstrap/talos/talconfig.yaml) and [Ceph](./kubernetes/apps/rook-ceph/rook-ceph/cluster/helmrelease.yaml#L97) |
| K8s controlplane, k8s workloads | `kube` (Rock 5B+) | RK3588 (4x A76 + 4x A55) | 24GB LPDDR5 | 32GB microSD for read-only root and boot, PLP SSDs for [Talos](./kubernetes/bootstrap/talos/talconfig.yaml) and [Ceph](./kubernetes/apps/rook-ceph/rook-ceph/cluster/helmrelease.yaml#L97) |
| K8s controlplane, k8s workloads | `kube` (Rock 5B+) | RK3588 (4x A76 + 4x A55) | 24GB LPDDR5 | 32GB microSD for read-only root and boot, PLP SSDs for [Talos](./kubernetes/bootstrap/talos/talconfig.yaml) and [Ceph](./kubernetes/apps/rook-ceph/rook-ceph/cluster/helmrelease.yaml#L97) |
| Cluster-external NFS (backups) | Raspberry Pi 4B |  | 4GB | 1TB SATA-via-USB3 Samsung QLC 870 Evo |

# Infra

- Cloudflare external ingress
- k8s_gateway for exposing DNS to LAN
- Authelia + lldap auth stack for external users
- Tailscale for remote private access
- Data:
  - CloudnativePG for relational databases
  - Rook-ceph for cluster internal storage
  - volsync for backup to and automatic restore from NFS and/or OVHCloud object storage
  - versitygw for access to NFS via S3-compatible interface (for database backups)
- Observability:
  - VictoriaMetrics
  - Grafana
  - VictoriaLogs

# Apps
- Karakeep bookmark manager and RSS reader
- FoundryVTT with an integrated SFTPGo container for remote filesystem access for the game admin
- OwnCloud Instant Scale (OCIS) for cloudnative filebrowser/sharing
- Continuwuity Matrix server

# Bootstrap

If the cluster is still running, reset the nodes to maintenance mode. You can skip this if you booted off of install media.

`task talos:reset`

Then wait for machinestatus to be maintenance on all nodes:

`talosctl get machinestatus -n <IP> --insecure`

Then bootstrap Talos:

`task bootstrap:talos`

Wait for machinestatus to be running on all nodes:

`talosctl get machinestatus -w` (because we have talconfig now, we can skip the IP and insecure flags)

Then bootstrap the apps with helmfile and watch the operators (flux and volsync) take over to bring everything back up:

`task bootstrap:apps`

The only app that may need some manual intervention after that is Tailscale, if the token has expired.


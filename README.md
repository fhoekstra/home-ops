# My Home Ops repo

Self-hosting and managing your setup through GitOps.
That is the journey I've started, using [@onedr0p](https://github.com/onedr0p)'s excellent [cluster template](https://github.com/onedr0p/cluster-template).

This repo uses [Talos Linux](https://www.talos.dev/) and [Flux](https://fluxcd.io/) to fully declaratively manage a Kubernetes cluster at home.

# Hardware

Currently 3 laptops that I got from the used market:

| Role | Model | CPU | RAM | SSD |
| ------------- | ------------- | -------------- | -------------- |-------|
| K8s controlplane, k8s workloads | Dell Latitude 5490 (Azerty) | i5-8350U (4C/8T) | 16GB | OS: 256GB SATA SK Hynix ; Ceph: 1.92TB Samsung SM863 (PLP) 2.5" SATA via USB3  |
| K8s controlplane, k8s workloads | Dell Latitude 5470 (Qwerty) | i5-6300U (2C/4T) | 16GB | OS: 256GB SATA Samsung ; Ceph: 480GB Samsung SM863a (PLP) 2.5" SATA via USB3 |
| K8s controlplane, k8s workloads | Lenovo IdeaPad S340-14IWL | i5-8265U (4C/8T) | 20GB | OS: 256GB SATA; Ceph: 480GB Samsung PM883 (PLP) 2.5" SATA via USB3 |
| Cluster-external NFS (backups) | Raspberry Pi 4B |  | 4GB | 1TB SATA-via-USB3 Samsung QLC 870 Evo |

# Infra

- Cloudflare external ingress
- k8s_gateway for exposing DNS to LAN
- Authelia + lldap auth stack for external users
- Tailscale for remote private access
- Data:
  - CloudnativePG for relational databases
  - Rook-ceph for cluster internal storage
  - volsync for backup to and automatic restore from NFS and/or S3
  - versitygw for access to NFS via S3-compatible interface (for database backups)
- Observability:
  - VictoriaMetrics
  - Grafana
  - VictoriaLogs

# Apps
- FoundryVTT with an integrated SFTPGo container for remote filesystem access
- OwnCloud Instant Scale (OCIS) for cloudnative filebrowser/sharing
- Continuwuity Matrix server

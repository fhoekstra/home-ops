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
| K8s controlplane, k8s workloads | Lenovo ThinkPad X230 | i5-3210M (2C/4T) | 16GB | OS: 250GB SATA Saumsung; Ceph: 256GB Samsung PM871b 2.5" SATA via USB3 |
| Cluster-external NFS (backups) | Raspberry Pi 4B |  | 4GB | 1TB SATA-via-USB3 Samsung QLC 870 Evo |


## TODO:

* Set up backups for single rep volumes
  - [x] Set up NFS outside the cluster
  - [x] Set up [volsync](https://volsync.readthedocs.io/en/stable/) to keep backups there
  - Add an external cloud object storage to volsync (planning to try [Intercolo](https://www.intercolo.net/en/object-storage), :eu:)
* Set up external-dns to be able to expose services internally
  - [x] get AdGuard Home working problem-free on the old Raspberry Pi
  - [x] forward the DNS zone to the k8s_gateway in the cluster
  - [x] test if a service that is only exposed internally resolves
* [x] Set up a database (let's start with just cnpg)
* Set up auth (either Authentik or Authelia + lldap)
* Start hosting some services
  - [x] [FoundryVTT](https://foundryvtt.com/)
  - [x] [Matrix](https://element.io/)
* [x] Set up a distributed storage system such as ~~[Longhorn](https://longhorn.io/)~~ settled on [rook-ceph](https://rook.io)
 because it works flawlessly with VolSync.
*  Once the setup is stable enough, migrate my [Home Assistant](https://www.home-assistant.io/) setup over, starting with its Add-Ons:
  - Mosquitto
  - Node-Red

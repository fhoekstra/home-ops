# My Home Ops repo

Self-hosting and managing your self-hosting setup through GitOps.
That is the journey I've started, using @onedr0p's excellent cluster template.

This repo uses Talos Linux and Flux to fully declaratively manage a Kubernetes cluster at home.

## TODO:

* Set up backups for single rep volumes
  - Set up NFS outside the cluster (ideally with NixOS)
  - Set up volsync to keep backups there
  - Add a cloud object storage to volsync (planning to try intercolo, :eu:)
* Set up external-dns to be able to expose services internally
  - get AdGuard Home working problem-free on the Raspberry Pi
  - install external-dns adguard webhook to the k8s cluster
  - test if a service that is only exposed internally resolves
* Start hosting some services
  - FoundryVTT
  - Matrix
* Once the setup is stable enough, migrate Home Assistant over
* Set up a distributed filesystem?


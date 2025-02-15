# My Home Ops repo

Self-hosting and managing your setup through GitOps.
That is the journey I've started, using [@onedr0p](https://github.com/onedr0p)'s excellent [cluster template](https://github.com/onedr0p/cluster-template).

This repo uses [Talos Linux](https://www.talos.dev/) and [Flux](https://fluxcd.io/) to fully declaratively manage a Kubernetes cluster at home.

## TODO:

* Set up backups for single rep volumes
  - Set up NFS outside the cluster (ideally with [NixOS](https://search.nixos.org/options?channel=24.11&from=0&size=50&sort=relevance&type=packages&query=services.nfs))
  - Set up [volsync](https://volsync.readthedocs.io/en/stable/) to keep backups there
  - Add a cloud object storage to volsync (planning to try [Intercolo](https://www.intercolo.net/en/object-storage), :eu:)
* Set up external-dns to be able to expose services internally
  - get AdGuard Home working problem-free on the old Raspberry Pi
  - install [external-dns adguard webhook](https://github.com/muhlba91/external-dns-provider-adguard) to the k8s cluster
  - test if a service that is only exposed internally resolves
* Start hosting some services
  - [FoundryVTT](https://foundryvtt.com/)
  - [Matrix](https://element.io/)
* Set up a distributed storage system such as [Longhorn](https://longhorn.io/)
* Once the setup is stable enough, migrate [Home Assistant](https://www.home-assistant.io/) over

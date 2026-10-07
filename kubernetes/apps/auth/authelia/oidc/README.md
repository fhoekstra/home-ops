# Authelia OIDC client management (Flux ResourceSet)

OIDC clients for Authelia are managed declaratively with the Flux Operator's
`ResourceSet` and `ResourceSetInputProvider`, so that onboarding a new client
does not require touching Authelia's HelmRelease or configuration at all.

## How it works

```
.                                   git (SOPS)                    in-cluster
│
│  oidc/clients/client-<app>.sops.yaml ─┐
│                                       │ kustomize patches           ┌──────────────────────────────┐
│  └────────────────────────────────────┴────────────────────────────►│ Secret authelia-oidc-clients-credentials
│                                                                     │   clients.<app>.client-id
│  oidc/rsip.yaml (client registry) ──► ResourceSetInputProvider ────►│   clients.<app>.client-secret
│                                       (Static, exportedInputs)      │   clients.<app>.client-secret-digest
│                                                   │
│  oidc/resourceset.yaml ◄── inputsFrom ────────────┘
│   (renders, per client)
│     ├─► ConfigMap authelia-oidc-clients-config (auth)
│     │     clients.<app>.yaml fragment (non-secret client options)
│     │     mounted into the Authelia pod at /config/oidc/clients
│     │
│     └─► Secret authelia-oidc-<app>-client (<app namespace>)
│           copyFrom: auth/authelia-oidc-clients-credentials
│           (client_id/secret available to the application)
│
│  app/config/configuration.yaml (startup template)
│     identity_providers.oidc.clients:
│       glob("/config/oidc/clients/*.yaml") → fileContent | fromYaml
│       credentials via fileContent("/secrets/oidc/clients.<app>...")
```

- `oidc/rsip.yaml` is the single declarative registry of OIDC clients
  (`ResourceSetInputProvider`, type `Static`).
- `oidc/resourceset.yaml` consumes that registry via `inputsFrom` and renders,
  for every client:
  1. a fragment file into the `authelia-oidc-clients-config` ConfigMap, and
  2. a copy of the combined credentials Secret into the application's own
     namespace (via the `fluxcd.controlplane.io/copyFrom` annotation), so
     applications never need cross-namespace secretKeyRefs.
- `app/config/configuration.yaml` globs the mounted fragment files at startup
  and assembles `identity_providers.oidc.clients` / `claims_policies`, injecting
  `client_id` / `client_secret` from the combined credentials Secret.
- The per-client credentials themselves are SOPS-encrypted patch files in
  `oidc/clients/`, merged into the `authelia-oidc-clients-credentials` Secret by
  kustomize (requires Flux ≥ 2.5, which decrypts SOPS patch files pre-build).

## Onboarding a new client

1. Generate and register the credentials (also appends the patch entry to
   `oidc/kustomization.yaml`):

   ```
   task oidc:create-client APP=<app>
   ```

   The task prints a ready-to-paste snippet for the registry.

2. Add the client to the registry in `oidc/rsip.yaml`
   (`spec.defaultValues.clients`), e.g.:

   ```yaml
   - app: immich
     namespace: photos
     client:
       client_name: Immich
       redirect_uris:
         - https://immich.example.com/auth/login
       scopes:
         - openid
         - profile
         - email
       require_pkce: true
   ```

   `client` accepts every Authelia OIDC client option **except**
   `client_id` / `client_secret`, which are injected at startup from the
   credentials Secret. Optional `claims_policies` (and any other
   `identity_providers.oidc` subsection that should be assembled per client,
   e.g. `authorization_policies`) can be extended the same way in
   `app/config/configuration.yaml`.

3. Point the application at the synced Secret `authelia-oidc-<app>-client`
   in its own namespace, e.g.:

   ```yaml
   GTS_OIDC_CLIENT_ID:
     valueFrom:
       secretKeyRef:
         name: authelia-oidc-gotosocial-client
         key: clients.gotosocial.client-id
   GTS_OIDC_CLIENT_SECRET:
     valueFrom:
       secretKeyRef:
         name: authelia-oidc-gotosocial-client
         key: clients.gotosocial.client-secret
   ```

   The synced Secret contains the keys of *all* clients (key names are
   prefixed with `clients.<app>.`), because `copyFrom` replicates the whole
   Secret. Keep the `${CLUSTER_DOMAIN}`-style substitutions in mind: they are
   substituted by Flux postBuild in `rsip.yaml` like any other manifest.

That's it — no changes to the HelmRelease or the Authelia configuration.

## Rotating a client

```
task oidc:rotate-client APP=<app>
```

Rotates the secret (client id is kept) in the SOPS patch. Once Flux
reconciles, the `reconcile.fluxcd.io/watch: Enabled` label on the combined
Secret triggers a ResourceSet reconciliation, `copyFrom` updates the synced
Secrets, and Reloader restarts Authelia (and applications that mount the
synced Secret via `reloader.stakater.com/auto`).

## Removing a client

1. Delete the client entry from `oidc/rsip.yaml`.
2. Remove the patch entry from `oidc/kustomization.yaml` and delete
   `oidc/clients/client-<app>.sops.yaml`.
3. Update the application to stop referencing the synced Secret; the ResourceSet
   garbage-collects `authelia-oidc-<app>-client` once the registry entry is gone.

## Failure modes

- A client registered in `rsip.yaml` **without** credentials: Authelia fails to
  start with a clear error
  (`error calling fileContent: open /secrets/oidc/clients.<app>.client-id: no
  such file or directory`). Credentials without a registry entry are inert.
- The ResourceSet reconciles only after `authelia-oidc-clients-credentials`
  exists and `authelia-oidc-clients-inputs` is ready (`spec.dependsOn`), and the
  `authelia` Kustomization depends on `authelia-oidc` (`wait: true`), so the
  HelmRelease never deploys before the fragment ConfigMap exists.
- Fragment files are rendered by the ResourceSet; a malformed fragment is
  skipped silently by the `fromYaml`-based assembly. Malformed registry
  entries fail the ResourceSet build (`Ready` condition) instead.

## Trade-offs

- The registry is a single `Static` provider holding an array of clients. Flux
  Operator resources render per input set, so a shared object (the fragment
  ConfigMap) can only be assembled from one input set; one RSIP per client
  cannot feed a single ConfigMap. The trade-off: adding a client is an edit to
  one declarative manifest rather than a new file per client.
- The `copyFrom`-synced application Secrets contain all clients' credentials
  (keys are namespaced with `clients.<app>.`). For stricter isolation, per-app
  source Secrets with per-app `copyFrom` targets would be needed instead.

## Requirements

- Flux Operator (chart `flux-operator` ≥ 0.61.0) for `ResourceSet` /
  `ResourceSetInputProvider` / `copyFrom`.
- Flux ≥ 2.5 for SOPS decryption of kustomize patch files.
- `task`, `docker`, `sops`, `yq` for the `oidc:` tasks.

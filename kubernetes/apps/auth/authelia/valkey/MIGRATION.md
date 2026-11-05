# Dragonfly → Valkey migration (Authelia session store)

This directory contains the Valkey replacement for the `dragonfly-auth` Dragonfly
instance plus a one-shot bulk import using [RedisShake](https://github.com/tair-opensource/RedisShake).

The migration is split across **two branches** that must be merged **in order,
with time in between**:

| Branch | Purpose | State |
| --- | --- | --- |
| `dragonfly-to-valkey-step-1` | Deploy Valkey alongside Dragonfly, bulk-import the data | **this branch** |
| `dragonfly-to-valkey-step-2` | Cut Authelia over to Valkey, decommission Dragonfly | pending |

---

## Why

- [Valkey](https://valkey.io/) is the Linux Foundation-governed fork of Redis OSS
  7.2 with a large ecosystem. Dragonfly requires its own operator for
  master/failover management, which is a lot of machinery for a single small
  session cache.
- The cache holds Authelia sessions, including `remember_me: 6M` sessions.
  Losing it means every user (including all OIDC clients) gets logged out, so
  the **existing** keyspace is imported. Keys **written during the migration
  window** are accepted as lost (users would sign in once more).

## Method: one-shot bulk import with RedisShake

[RedisShake](https://tair-opensource.github.io/RedisShake/en/) (maintained by
Alibaba's Tair team) is the de-facto standard migration tool for Redis-compatible
stores — it is what [Dragonfly Cloud](https://www.dragonflydb.io/docs/cloud/migrate)
and [Aiven](https://aiven.io/docs/products/valkey/howto/migrate-dragonfly-to-valkey)
use/document for exactly this path.

- **Why `scan_reader` mode:** Dragonfly does not implement `PSYNC`/`SYNC` as a
  *master* ([dragonflydb/dragonfly#2662](https://github.com/dragonflydb/dragonfly/issues/2662)),
  so no replication-based reader can attach to it. `scan_reader` walks the
  source with `SCAN`, reads each key with `DUMP` + `PTTL` and writes it with
  `RESTORE` — key types and TTLs are preserved.
- **Why it fits a Kubernetes Job:** with KSN (keyspace notifications) disabled,
  RedisShake exits cleanly once the scan completes (`all done`, exit 0), and
  v4 is explicitly designed for *one-time data migrations* (no checkpoint — a
  restart re-scans from the beginning, which is fine because the job is
  idempotent in `rewrite` mode).
- **Validated** against the real Dragonfly v2.0.2 (emulated cluster, password
  auth) → Valkey 9.1.3: all base types, TTLs (down to exact milliseconds) and
  no-expiry keys survived; 100k keys / 230 MB took **18 s** through Docker
  Desktop networking, extrapolating to **~2 minutes for 700k keys / 1.6 GB**.

### Accepted trade-off

Everything present when the import finishes is migrated. Keys written to
Dragonfly *after* the import completes are **not** migrated — Authelia sessions
created in that window are dropped and those users sign in once more. To
minimize the window, re-run the import right before merging step 2 (see below).

---

## Step 1 — deploy Valkey and import the data (this branch)

Adds, without touching Dragonfly or Authelia behavior:

- `helmrelease.yaml`: `valkey-auth` (app-template), StatefulSet with Valkey
  9.1.3 (pinned digest), AOF `everysec` + RDB snapshots on `ceph-block`,
  `maxmemory 384mb` / `noeviction`, `redis_exporter` sidecar + ServiceMonitor,
  network policies mirroring the Dragonfly ones.
- `secret.sops.yaml`: `valkey-auth-secret` — same password as
  `dragonfly-auth-secret`, so both instances accept identical credentials and
  the import can authenticate against both.
- `migration/`: a `valkey-migrate` Job running RedisShake 4.7.0 (pinned
  digest) with `shake.toml` from a ConfigMap. It is applied by its own Flux
  Kustomization **after** `valkey-auth` is healthy, so it runs automatically
  once on merge. Passwords are injected from both Secrets via RedisShake's
  `${VAR}` config substitution — nothing secret lives in the ConfigMap.
- `MIGRATION.md`: this document.

### After merging step 1

1. Wait for reconciliation:

   ```sh
   flux get kustomizations valkey-auth valkey-migrate
   flux get helmreleases --all-namespaces | grep valkey
   ```

   `valkey-migrate` only applies once `valkey-auth` is healthy, and is Ready
   once the Job completed.

2. Check the import result:

   ```sh
   kubectl --namespace auth logs job/valkey-migrate
   ```

   The log should end with `all done`. Compare key counts:

   ```sh
   kubectl --namespace auth exec statefulset/valkey-auth -c valkey-auth -- \
     sh -c 'valkey-cli --no-auth-warning -a "$VALKEY_PASSWORD" dbsize'
   kubectl --namespace auth exec statefulset/dragonfly-auth-0 -- \
     redis-cli --no-auth-warning -a "$(kubectl -n auth get secret dragonfly-auth-secret \
     -o jsonpath='{.data.AUTHELIA_SESSION_REDIS_PASSWORD}' | base64 -d)" dbsize
   ```

   The two numbers should match (keys expiring in between are the exception,
   and that is expected behavior).

3. **Re-running the import** (after a failure, or right before merging step 2
   to shrink the dropped-keys window):

   ```sh
   kubectl --namespace auth delete job valkey-migrate
   flux reconcile kustomization valkey-migrate --namespace flux-system
   ```

   Re-runs are idempotent (`rdb_restore_command_behavior = "rewrite"`) and
   only safe while Valkey is not yet serving live traffic.

### Rollback

`git revert` the merge and let Flux prune. Nothing referenced Valkey yet, so
there is no impact on Authelia.

---

## Step 2 — cut over and decommission (`dragonfly-to-valkey-step-2`)

One atomic Flux apply:

- Authelia `envFrom` → `valkey-auth-secret` (host now points at
  `valkey-auth.auth.svc.cluster.local`, same password), which rolls the
  Authelia pods.
- The Authelia Kustomization dependency swaps from `dragonfly-auth` to
  `valkey-auth` (also guarantees correct ordering on future bootstraps).
- The `dragonfly-auth` Dragonfly CR, its secret, network policies, PodMonitor
  and Flux Kustomization are removed, together with the `dragonfly-operator`
  HelmRelease, OCIRepository and Kustomization.
- The `valkey-migrate` Kustomization and Job are removed — do **not** re-run
  the import after this point: it would overwrite live Valkey data with stale
  Dragonfly data.
- The README infra list is updated.

### Before merging

1. Confirm the import job completed and the dbsize matches (see above).
2. Optionally re-run the import once more right before merging (see above) to
   shrink the dropped-keys window to minutes.

### Notes

- Deleting the `Dragonfly` CR removes the Dragonfly StatefulSet and services
  via the operator. Its data is memory-only and stale by then — safe to lose.
- The operator chart was installed with `crds: keep: true`, so the
  `dragonflies.dragonflydb.io` CRD **stays in the cluster** afterwards.
  Harmless; delete manually if desired:
  `kubectl delete crd dragonflies.dragonflydb.io`.
- The `dragonfly-auth-secret` is pruned with the Dragonfly Kustomization.
  Nothing references it anymore at that point.

### Rollback

`git revert` the merge. Dragonfly comes back **empty** (it has no persistence —
its pods restart with no data), so every user signs in once more. That is the
same cost as the accepted migration trade-off, which is why verifying the
import *before* merging this step is the important gate.

---

## Reusing this for a larger production migration (700k keys / 1.6 GB)

The `migration/` directory is self-contained: copy it into the target repo,
point the two `address` values in `shake.toml` at the source and target
services, and wire the password env vars to the appropriate Secrets.

Measured and expected at this scale:

- **Throughput:** 100k keys / 230 MB took ~18 s in a constrained Docker
  Desktop network; 700k keys / 1.6 GB extrapolates to **~2 minutes**. Even an
  order of magnitude slower production network stays in the tens of minutes.
- **Tuning:** `count = 1000` in `scan_reader` is already set (the RedisShake
  default of 1 is pathologically slow for large keyspaces). Raise
  `activeDeadlineSeconds` if the source is remote or slow.
- **Source impact:** `DUMP` is CPU-intensive on the source — RedisShake's docs
  cite source CPU going from 47% → 91% at ~150k write QPS while scanning. Run
  the import off-peak; lower `count` to reduce pressure.
- **Target sizing:** this repo's Valkey runs with `maxmemory 384mb`, sized for
  Authelia's small session keyspace. For a 1.6 GB dataset raise `maxmemory`
  and the container memory limit in `helmrelease.yaml` accordingly (leave
  headroom for fork copy-on-write during AOF rewrites), plus the PVC size.
- **No resume:** RedisShake has no checkpoint; an interrupted job re-scans
  everything. With `rewrite` mode that is safe, just slower.
- **Verification:** compare `DBSIZE` on both sides, spot-check TTLs
  (`TTL <key>`) and types (`TYPE <key>`), and watch the job log for `all done`
  with zero errors. For a full value-by-value comparison, RIOT-X's
  `sync2 --compare FULL` is a good complement.

---

## Operations cheatsheet (Valkey)

```sh
# Ping / dbsize / keyspace info
kubectl --namespace auth exec statefulset/valkey-auth -c valkey-auth -- \
  sh -c 'valkey-cli --no-auth-warning -a "$VALKEY_PASSWORD" ping'
kubectl --namespace auth exec statefulset/valkey-auth -c valkey-auth -- \
  sh -c 'valkey-cli --no-auth-warning -a "$VALKEY_PASSWORD" dbsize'
kubectl --namespace auth exec statefulset/valkey-auth -c valkey-auth -- \
  sh -c 'valkey-cli --no-auth-warning -a "$VALKEY_PASSWORD" info keyspace'
kubectl --namespace auth exec statefulset/valkey-auth -c valkey-auth -- \
  sh -c 'valkey-cli --no-auth-warning -a "$VALKEY_PASSWORD" info persistence'

# Metrics are scraped by VictoriaMetrics via the valkey-auth ServiceMonitor
# (redis_exporter sidecar, port 9121).
```

## Notes & trade-offs

- **HA:** Dragonfly ran 3 replicas with operator-managed failover; Valkey runs
  a single replica with AOF persistence. A single pod loss costs a short blip
  (seconds, AOF reload) instead of nothing, but a *full cluster reboot* — which
  previously lost every session (Dragonfly had no persistence) — now loses
  nothing. If HA parity is wanted later, add Valkey Sentinel and switch
  Authelia to `session.redis.high_availability`; that is out of scope here.
- **Backups:** Dragonfly had none. Consider adding a volsync ReplicationSource
  for the `data-valkey-auth-0` PVC as a follow-up.
- **Compatibility:** Authelia's session keys are plain strings/hashes; no
  module data types are in use. Dragonfly's `DUMP` payloads are RDB-format and
  are accepted by Valkey's `RESTORE` (validated locally). The Dragonfly-specific
  flags on the old instance (`--cluster_mode=emulated`, `--lock_on_hashtags`,
  `--default_lua_flags=allow-undeclared-keys`) were Dragonfly
  mitigations/workarounds and have no equivalent or need on Valkey.

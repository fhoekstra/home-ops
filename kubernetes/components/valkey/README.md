Reusable single-node Valkey (Redis-compatible) deployment

## Usage

In the app's `ks.yaml`:

```yaml
spec:
  components:
    - ../../../../components/valkey
  postBuild:
    substitute:
      APP: myapp
```

Then make the app's HelmRelease depend on it and point it at the Service:

```yaml
spec:
  dependsOn:
    - name: "${APP}-valkey"
  values:
    env:
      REDIS_HOST: myapp-valkey
      REDIS_PORT: "6379"
```

## Naming

All resource names derive from the instance name, `${APP}-valkey` by default. To
run an instance under a different name (e.g. when an app needs a second store),
set `VALKEY_NAME` in the postBuild substitutes:

```yaml
postBuild:
  substitute:
    APP: myapp
    VALKEY_NAME: myapp-cache
```

The `VALKEY_SECRET` default (see below) follows the instance name.

## Password

The component contains no credentials. The consuming app provides the password in
a `kubernetes.io/basic-auth` Secret, named after the instance name (`<APP>-valkey`
by default) with the standard `username` and `password` keys:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-valkey
type: kubernetes.io/basic-auth
stringData:
  username: myapp
  password: <sops-encrypted password>
```

The component injects the `password` key into the Valkey server (`--requirepass`)
and the metrics exporter. The app reads the same Secret (e.g. via `envFrom` or
`secretKeyRef`) to build its own connection credentials, so both sides always
match.

To use a differently named Secret, set `VALKEY_SECRET` in the postBuild
substitutes:

```yaml
postBuild:
  substitute:
    APP: myapp
    VALKEY_SECRET: my-shared-valkey
```

## Notes

- The component creates one Valkey instance per include (per instance name).
  Multiple apps in the same namespace deconflict through their `${APP}`-derived
  names. To give a single app a second instance, wire it through an additional
  Flux Kustomization with a distinct `APP`/`VALKEY_NAME` value, e.g.
  `APP: myapp-cache` → `myapp-cache-valkey`.
- Data is persisted on a 2Gi `ceph-block` PVC (AOF + RDB snapshots) that is
  retained even when the StatefulSet is deleted.
- `maxmemory-policy` is `noeviction`: when the store is full, writes fail instead
  of silently dropping data. The memory limit (512Mi) and `maxmemory` (384mb) are
  fixed; bump both in the component if an app needs a bigger store.
- Metrics are exposed on port 9121 (redis_exporter) and scraped via a
  ServiceMonitor.
- NetworkPolicies only allow same-namespace clients on port 6379 and the
  observability namespace on port 9121. Add your own NetworkPolicy in the app for
  cross-namespace clients.
- Avoid passwords containing quotes or shell metacharacters: they are passed via
  `--requirepass` and interpolated by the health-check probes.

Reusable Anubis (bot-protection proxy) deployment for any app, modelled after the
[mortebrume's anubis component](https://github.com/mortebrume/home-ops).

Instead of running Anubis as a sidecar container, each consuming app gets its own
`<APP>-anubis` HelmRelease (app-template) in the app's namespace. The HTTPRoute of the
app then points at the `<APP>-anubis` Service (port 8080) instead of the app itself.

## Usage

In the app's `ks.yaml`:

```yaml
spec:
  components:
    - ../../../../components/anubis
  postBuild:
    substitute:
      APP: myapp
      ANUBIS_TARGET: http://myapp.<namespace>.svc:8080
```

- `APP`: name of the consuming app, used for resource names (`<APP>-anubis`).
- `ANUBIS_TARGET`: the upstream service Anubis proxies to.

Then route traffic through it in the app's HelmRelease (or HTTPRoute):

```yaml
rules:
  - backendRefs:
      - name: myapp-anubis
        port: 8080
```

## Notes

- The ED25519 signing key is shared for all apps and stored in this component as a
  SOPS secret (`<APP>-anubis-key`), so all Anubis instances produce the same challenge
  cookies as long as they share a domain.
- The policy imports Anubis' built-in default policy (`(data)/meta/default-config.yaml`).
- Metrics are exposed on port 9090 and scraped via a ServiceMonitor.
- Envoy gateways must set `X-Real-Ip` for Anubis to see the client IP
  (see the ClientTrafficPolicy in the envoy-gateway app).
- Envoy SecurityPolicies doing ext-auth against `<APP>-anubis` from another
  namespace need a ReferenceGrant for the Service in the app's namespace (see
  the ReferenceGrant in the authelia app), and should pass `X-Real-Ip` through
  `headersToExtAuth`.

# LiteLLM Helm Chart

Minimal chart to deploy a LiteLLM gateway on OpenShift with optional persistence, configurable API key handling, and flexible master/salt key sourcing.

## Features
- Deployment, Service, ConfigMap (model list), optional Route (if you add one)
- Optional PVC for local data (`persistence.enabled`)
- Liveness & readiness probes (HTTP on configurable path)
- OpenAI API key injection via:
  1. Chart‑managed secret (default when `apiKeys.enabled=true` and no existing secret specified)
  2. Existing external secret (`apiKeys.existingSecret.name`)
  3. Disabled entirely (`apiKeys.enabled=false`)
- Master & salt keys for LiteLLM sourced from:
  1. Existing secret (`masterSalt.existingSecret.name`)
  2. Chart‑managed secret (`masterSalt.createSecret=true`)
  3. Inline values (`env.LITELLM_MASTER_KEY` / `env.LITELLM_SALT_KEY`)

## Values Overview
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | 1 | Pod replicas |
| image.repository | string | ghcr.io/berriai/litellm | Image repo |
| image.tag | string | main-latest | Image tag |
| service.port | int | 4000 | Service port |
| env.* | string | see values.yaml | Core LiteLLM env vars |
| config.litellm_config | string | example model list | Inlined config.yml content |
| persistence.enabled | bool | true | Enable PVC |
| persistence.size | string | 1Gi | PVC size |
| persistence.mountPath | string | /data | Mount path |
| probes.path | string | /health | Probe endpoint |
| apiKeys.enabled | bool | false | Toggle API key injection |
| apiKeys.openaiKey | string | "" | OpenAI key (chart secret) |
| apiKeys.existingSecret.name | string | "" | Use existing secret name (disables chart secret) |
| apiKeys.existingSecret.key | string | OPENAI_API_KEY | Key inside existing secret |
| masterSalt.existingSecret.name | string | "" | Existing secret for master/salt |
| masterSalt.createSecret | bool | false | Create chart secret if no existing secret |
| masterSalt.masterKey | string | "" | Master key (chart secret) |
| masterSalt.saltKey | string | "" | Salt key (chart secret) |

## API Key Logic
Priority:
1. If `apiKeys.enabled=false` -> no secret/env.
2. If `apiKeys.enabled=true` AND `apiKeys.existingSecret.name` set -> reference external secret.
3. Else create `<release>-litellm-apikeys` secret with `apiKeys.openaiKey`.

## Master/Salt Logic
Priority:
1. If `masterSalt.existingSecret.name` set -> reference that secret.
2. Else if `masterSalt.createSecret=true` -> create `<release>-litellm-master-salt` with provided keys.
3. Else use inline `env.LITELLM_MASTER_KEY` / `env.LITELLM_SALT_KEY` (defaults to empty / CHANGEME fallback in container).

## Example (Chart‑managed secrets)
```yaml
apiKeys:
  enabled: true
  openaiKey: sk-xxxx
masterSalt:
  createSecret: true
  masterKey: super-master
  saltKey: super-salt
```

## Example (All external secrets)
```yaml
apiKeys:
  enabled: true
  existingSecret:
    name: shared-openai
    key: OPENAI_API_KEY
masterSalt:
  existingSecret:
    name: litellm-master-salt
    masterKey: LITELLM_MASTER_KEY
    saltKey: LITELLM_SALT_KEY
```

## Argo CD Application Snippet
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: litellm
spec:
  source:
    repoURL: https://github.com/your/org.git
    path: charts/litellm
    targetRevision: main
    helm:
      values: |
        apiKeys:
          enabled: true
          openaiKey: sk-xxxx
        masterSalt:
          createSecret: true
          masterKey: super-master
          saltKey: super-salt
  destination:
    namespace: litellm
    server: https://kubernetes.default.svc
  syncPolicy:
    automated: {}
```

### Argo CD Scenarios

1. No API key / Inline master & salt (dev):
```yaml
values: |
  apiKeys:
    enabled: false
  masterSalt:
    createSecret: false
  env:
    LITELLM_MASTER_KEY: dev-master
    LITELLM_SALT_KEY: dev-salt
```

2. Chart-managed all secrets:
```yaml
values: |
  apiKeys:
    enabled: true
    openaiKey: sk-xxxx
  masterSalt:
    createSecret: true
    masterKey: super-master
    saltKey: super-salt
```

3. All external (pre-provisioned) secrets:
```yaml
values: |
  apiKeys:
    enabled: true
    existingSecret:
      name: shared-openai
      key: OPENAI_API_KEY
  masterSalt:
    existingSecret:
      name: litellm-master-salt
      masterKey: LITELLM_MASTER_KEY
      saltKey: LITELLM_SALT_KEY
```

4. Mixed (external OpenAI, chart-managed master/salt):
```yaml
values: |
  apiKeys:
    enabled: true
    existingSecret:
      name: shared-openai
  masterSalt:
    createSecret: true
    masterKey: super-master
    saltKey: super-salt
```

### Values Strategy Diff
| Scenario | apiKeys.enabled | apiKeys.openaiKey | apiKeys.existingSecret.name | masterSalt.existingSecret.name | masterSalt.createSecret | Secrets Created by Chart |
|----------|-----------------|-------------------|-----------------------------|--------------------------------|-------------------------|--------------------------|
| Dev (none) | false | (ignored) | (empty) | (empty) | false | none |
| Chart-managed all | true | set | (empty) | (empty) | true | <rel>-litellm-apikeys, <rel>-litellm-master-salt |
| All external | true | (ignored) | shared-openai | litellm-master-salt | false | none |
| Mixed | true | (ignored) | shared-openai | (empty) | true | <rel>-litellm-master-salt |

`<rel>` = release name prefix used in Helm full name helper.

### Quick Validation Commands
Render with mixed strategy:
```bash
helm template test ./charts/litellm \
  --set apiKeys.enabled=true \
  --set apiKeys.existingSecret.name=shared-openai \
  --set masterSalt.createSecret=true \
  --set masterSalt.masterKey=abc --set masterSalt.saltKey=def |
  grep -E 'kind: Secret|name: test-l' -n
```

List created secrets in cluster (after sync):
```bash
kubectl get secret -n litellm | grep litellm
```


## Persistence
Disable if you do not need local storage:
```yaml
persistence:
  enabled: false
```

## Probes
Override path / timing if needed:
```yaml
probes:
  path: /health
  liveness:
    initialDelaySeconds: 5
```

## Security Notes
- Provide real secrets via CI/CD secret management (never commit real keys in git).
- Rotate keys regularly.

## Future Enhancements (potential)
- ServiceMonitor / metrics
- HorizontalPodAutoscaler
- Resource requests/limits defaults
- Model routing customization via separate values structure

## Verification
Render templates locally:
```bash
helm template test ./charts/litellm --set apiKeys.enabled=true --set apiKeys.openaiKey=dummy
```


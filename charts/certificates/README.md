## TODO

[ ] Patch the ingress controller to use the new certs /settings/cluster/globalconfig
---
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: default
  annotations:
    kustomize.toolkit.fluxcd.io/prune: disabled
    kustomize.toolkit.fluxcd.io/ssa: merge
spec:
  defaultCertificate:
    name: apps-wildcard-cert-tls


[ ] Patch the ingress controller to use the new certs /settings/cluster/globalconfig
        ---
        apiVersion: operator.openshift.io/v1
        kind: ApiServer

spec:
    servingCerts:
        namedCertificates:
        - names:
        - api.sno.roybales.com
        servingCertificate:
            name: api-cert-tls


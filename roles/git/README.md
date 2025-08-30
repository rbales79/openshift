# roles/git

This role deploys an ArgoCD `Application` that installs a Helm chart from a gist (or git repo) and pulls an additional `values.yaml` from a separate gist URL.

How it works

- `spec.source.repoURL` should point to the repo/gist that contains the Helm chart you want to install.
- `gist_values.values_url` should be a raw URL to a `values.yaml` file (for example a gist raw URL). The ArgoCD `Application` passes this URL to Helm via `--values=<url>` so Helm will fetch and merge it at render time.

Configuration

- Edit `roles/git/values.yaml` and set `spec.source.repoURL` and `gist_values.values_url` to your targets.

Example

- Chart repo: `https://gist.github.com/username/gistid.git`
- Values file (raw): `https://gist.githubusercontent.com/username/gistid/raw/values.yaml`

Notes and caveats

- Helm supports remote `-f/--values` using go-getter URLs (HTTP/HTTPS). Ensure the gist raw URL is accessible from the cluster.
- ArgoCD will pass the `--values` extra arg to Helm using the `helm.parameters` `extraArgs` trick in this template. Some ArgoCD versions may behave differently; test in a non-production environment first.

Next steps

1. Upload `example-values.yaml` to a public/private gist and copy the raw URL into `roles/git/values.yaml` -> `gist_values.values_url`.
2. Set `roles/git/values.yaml` -> `spec.source.repoURL` to the gist/git repo URL containing the chart (or any repo with the chart path set in `gist_values.chart_path`).
3. Apply the ArgoCD application manifest or let your GitOps pipeline pick up the change.

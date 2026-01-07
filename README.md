# DevOpsTask — Deploying to DigitalOcean Kubernetes (DOKS)

## What this repo does
This project demonstrates a simple, practical pipeline to run a small web app on DigitalOcean Kubernetes using:

- Terraform — provision a DOKS cluster (optional: Spaces bucket for remote Terraform state)
- Helm — package and deploy the application
- GitHub Actions — CI for Terraform (plan / apply) and Helm (deploy)

The goal is clarity and safety: no secrets in source control, small readable Terraform and Helm configs, and workflows you can inspect easily.

I configured Prometheus and Helm customizations.

---

## Repository layout
- `app/` — the application and Dockerfile
- `helm/hello-world/` — Helm chart for the app
- `terraform/` — Terraform code (provider, cluster, backend, outputs, helpers)
- `.github/workflows/` — GitHub Actions for Terraform and Helm

---

## Quick start (local development)
1. Clone the repo
   ```bash
   git clone <repo-url>
   cd DevopsTask
   ```

2. Set required secrets (do not commit them)
   - PowerShell
     ```powershell
     $env:DIGITALOCEAN_TOKEN = "<your-token>"
     $env:SPACES_ACCESS_KEY = "<spaces-access-key>"
     $env:SPACES_SECRET_KEY = "<spaces-secret-key>"
     ```
   - Bash
     ```bash
     export DIGITALOCEAN_TOKEN="<your-token>"
     export SPACES_ACCESS_KEY="<spaces-access-key>"
     export SPACES_SECRET_KEY="<spaces-secret-key>"
     ```

3. Provision infrastructure with Terraform
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

4. Save kubeconfig locally
   ```bash
   doctl kubernetes cluster kubeconfig save devops-cluster
   kubectl get nodes
   ```

5. Deploy the app with Helm
   ```bash
   helm upgrade --install hello helm/hello-world --namespace default --create-namespace
   kubectl rollout status deployment/hello -n default
   ```


---

## Terraform details
- Remote state: the repo is configured to use DigitalOcean Spaces (S3-compatible) if you provide `SPACES_ACCESS_KEY` and `SPACES_SECRET_KEY` as environment variables (the workflows map these to `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` when initializing the S3-compatible backend).
- Backend settings are intentionally left configurable; add the backend values at `terraform init` time or edit `terraform/backend.tf` (do not hardcode credentials).
- Sensitive variables are declared in `terraform/variables.tf` and expected to come from environment variables or CI secrets.

---

## CI / GitHub Actions
Workflows included:
- `.github/workflows/terraform-plan.yml` — runs on pull requests to show `terraform plan` output
- `.github/workflows/terraform-apply.yml` — runs on pushes to `main` and performs `terraform apply`
- `.github/workflows/deploy-helm.yml` — runs on push and manual dispatch, saves cluster kubeconfig using `doctl` and runs `helm upgrade -i`

Add these repository secrets (Settings → Secrets and variables → Actions):
- `DIGITALOCEAN_TOKEN` (for `doctl` and Terraform provider)
- `SPACES_ACCESS_KEY` and `SPACES_SECRET_KEY` (for Terraform backend in Spaces)

> Tip: Protect the `main` branch and require reviews to avoid accidental `terraform apply` runs.

---

## Security & key rotation
If you ever accidentally commit a secret, rotate it immediately:
1. Revoke and recreate the DigitalOcean API token (Control Panel → API → Tokens & Keys)
2. Revoke and recreate the Spaces access key
3. Update repository secrets and local environments

Also ensure `terraform.tfvars`, `*.tfstate`, and `.terraform/` are in `.gitignore` (already added).

---

## Troubleshooting: blank or empty responses from Ingress
1. Inspect the Ingress resource and events
   ```bash
   kubectl get ingress -A
   kubectl describe ingress <name> -n <namespace>
   ```
2. Check the ingress controller
   ```bash
   kubectl get pods -n ingress-nginx
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=200
   ```
3. Verify the service & endpoints
   ```bash
   kubectl get svc -n <app-namespace>
   kubectl get endpoints <svc-name> -n <app-namespace> -o yaml
   ```
4. Curl the LB with the Host header
   ```bash
   curl -v http://<EXTERNAL_IP>/ -H "Host: <INGRESS_HOST>"
   ```
5. Test from inside the cluster
   ```bash
   kubectl run --rm -it curl --image=radial/busyboxplus:curl -- curl -v http://<service>:<port>/
   ```

If you want, I can run a small script to collect these details and summarize the root cause.

---

## Monitoring — Prometheus & Grafana

I integrated Prometheus using the `kube-prometheus-stack` Helm chart with a small customization file (for example `helm/prometheus/values.yaml`). Commands I used and checks I ran:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace monitoring
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f helm/prometheus/values.yaml

kubectl get pods -n monitoring
kubectl get svc -n monitoring

# port-forward to access Prometheus and Grafana locally
k
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 
```

Notes:
- Put sensitive values (Grafana admin password, custom credentials) in Kubernetes secrets or in CI secrets — do not commit them to the repo.
- Use a `ServiceMonitor` or enable `serviceMonitors` in the chart values so Prometheus scrapes your app's `/metrics` endpoint.
- If using Ingress, enable ingress in the chart values and configure host/TLS/annotations there.
### Accessing Grafana UI

Grafana's admin user is `admin` by default. To find the admin password that the chart created as a Kubernetes secret:

Linux / macOS:
```bash
kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode; echo
# If your release or secret is named differently (for example `monitoring-grafana`), use:
kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode; echo
```

PowerShell:
```powershell
$pass = kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}";
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($pass))
```

If you used a different release name when installing the chart, replace `prometheus` in the secret name with your release name (for example: `<release>-grafana`).

To reset the Grafana admin password safely, upgrade the chart with an explicit password (preferred) and restart Grafana:
```bash
# Set a new password via Helm values (safe, idempotent)
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --set grafana.adminPassword='<new-password>'

# Restart Grafana deployment to pick up the new secret
kubectl rollout restart deployment prometheus-grafana -n monitoring
```

Notes:
- Keep Grafana credentials in CI or Kubernetes secrets, not in committed files.
- If you enabled ingress for Grafana, use that host to access the UI (or port-forward as shown above).
---

## Actions taken — Errors encountered & fixes ✅

- Added the DigitalOcean token to `terraform/terraform.tfvars` and ran `terraform apply` → error: `autoscale desired max nodes exceed limits` (not enough droplet quota). **Fix:** reduced `node_pool_count` to `2` and set autoscaling `min_nodes = 1`, `max_nodes = 3` in `terraform/terraform.tfvars`.

- Configuring the Spaces backend produced Terraform errors about retrieving AWS account details (`InvalidClientTokenId`) when initializing the S3-compatible backend. **Fix:** added `skip_requesting_account_id = true` to `terraform/backend.tf` and moved Spaces credentials to environment variables (`SPACES_ACCESS_KEY` / `SPACES_SECRET_KEY`) rather than hardcoding them.

- Found hardcoded secrets and API tokens in files and local state. **Fixes implemented:** removed hardcoded secrets from tracked files, added `terraform/terraform.tfvars.example`, created `set-env.sh` and `set-env.ps1` to guide setting environment variables, updated `.gitignore` to exclude `terraform.tfvars`, `*.tfstate` and `.terraform/`, and added GitHub Actions workflows to use repository secrets.

- Discovered sensitive data inside local Terraform state files (`terraform/terraform.tfstate`, `terraform/terraform.tfstate.backup`, and `.terraform/terraform.tfstate`). **Recommended cleanup (run locally or allow me to run after confirmation):**

```bash
# If git refuses due to safe.directory, add an exception first:
# git config --global --add safe.directory '<repo-path>'

git rm --cached terraform/terraform.tfstate terraform/terraform.tfstate.backup
git rm -r --cached terraform/.terraform
git add .gitignore
git commit -m "Remove sensitive Terraform state files and update .gitignore"
git push

# Then remove local copies
rm terraform/terraform.tfstate terraform/terraform.tfstate.backup
rm -rf terraform/.terraform
```

- Rebuilt `terraform/main.tf` (clean cluster + node pool), added outputs, and created GitHub Actions workflows for Terraform plan/apply and Helm deployment.

- Configured Prometheus and Helm customizations for monitoring and chart flexibility.

**Important:** If any secret was exposed, rotate it immediately (DigitalOcean API tokens and Spaces keys), update repository secrets, and re-run `terraform init` if you move state.

---

## Contributing & next steps
- Open a PR for changes; CI will run `terraform-plan.yml` and show the plan output.
- For safety, keep secrets in GitHub Actions secrets and deploy from the CLI or Actions (no local helper script is required).

---


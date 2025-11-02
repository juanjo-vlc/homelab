# SOPS + ArgoCD Test Setup

This directory contains a test setup to verify that ArgoCD with SOPS support is working correctly with GPG-encrypted secrets.

## Directory Structure

```
sops-tests/
├── .sops.yaml                    # SOPS configuration file
├── manifests/                    # Plain (unencrypted) manifests
│   ├── test-secret.yaml         # Plain secret (for reference)
│   ├── test-configmap.yaml      # ConfigMap
│   └── test-pod.yaml            # Test pod that uses the secret
├── encrypted/                    # Encrypted manifests
│   └── test-secret.enc.yaml     # SOPS-encrypted secret
├── kustomization.yaml           # Kustomize configuration
├── argocd-application.yaml      # ArgoCD Application manifest
└── README.md                    # This file
```

## Prerequisites

1. ArgoCD installed with SOPS support
2. GPG key configured in ArgoCD (key fingerprint: `41DB93BCEEA30326`)
3. kubectl access to your cluster
4. SOPS CLI installed locally

## GPG Key Information

The test uses the following GPG key:
- **Key ID**: `41DB93BCEEA30326`
- **Full Fingerprint**: `4E307EDF57A9B6A79A22F9C041DB93BCEEA30326`
- **Identity**: anthrax.garmo.local (k8s) <anthrax@garmo.local>

## Quick Start

### 1. Verify SOPS Configuration

The `.sops.yaml` file configures SOPS to:
- Encrypt all `.yaml` files
- Only encrypt the `data` and `stringData` fields (keeps metadata readable)
- Use the GPG key `41DB93BCEEA30326`

### 2. Test SOPS Encryption/Decryption Locally

```bash
# View encrypted secret
cat encrypted/test-secret.enc.yaml

# Decrypt and view the secret
sops -d encrypted/test-secret.enc.yaml

# Re-encrypt after making changes to the plain secret
sops --encrypt manifests/test-secret.yaml > encrypted/test-secret.enc.yaml
```

### 3. Verify ArgoCD GPG Key Import

Make sure the GPG key is imported into ArgoCD:

```bash
# Export your GPG private key
gpg --export-secret-keys --armor 41DB93BCEEA30326 > /tmp/gpg-key.asc

# Import into ArgoCD (if not already done)
kubectl create secret generic sops-gpg \
  --from-file=sops.asc=/tmp/gpg-key.asc \
  -n argocd

# Verify ArgoCD repo-server has the key
kubectl exec -n argocd deploy/argocd-repo-server -- gpg --list-keys

# Clean up the exported key
rm /tmp/gpg-key.asc
```

### 4. Deploy with kubectl (Manual Test)

Test the encrypted secret directly with kubectl:

```bash
# Decrypt and apply the secret
sops -d encrypted/test-secret.enc.yaml | kubectl apply -f -

# Apply other manifests
kubectl apply -f manifests/test-configmap.yaml
kubectl apply -f manifests/test-pod.yaml

# Check if the pod can read the secrets
kubectl logs sops-test-pod

# Expected output:
# Username: admin
# Password: supersecretpassword123
# API Key: sk-1234567890abcdef

# Cleanup
kubectl delete pod sops-test-pod
kubectl delete secret test-sops-secret
kubectl delete configmap test-sops-configmap
```

### 5. Deploy with ArgoCD

#### Option A: Using kubectl

1. Update the `repoURL` in `argocd-application.yaml` with your Git repository
2. Push this directory to your Git repository
3. Apply the ArgoCD application:

```bash
kubectl apply -f argocd-application.yaml
```

#### Option B: Using ArgoCD CLI

```bash
# Login to ArgoCD
argocd login <argocd-server>

# Create the application
argocd app create sops-test-app \
  --repo https://github.com/YOUR_USERNAME/YOUR_REPO.git \
  --path sops-tests/encrypted \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### 6. Verify ArgoCD Deployment

```bash
# Check application status
kubectl get applications -n argocd
argocd app get sops-test-app

# Check if resources are created
kubectl get secrets test-sops-secret
kubectl get configmap test-sops-configmap
kubectl get pod sops-test-pod

# Verify the secret was decrypted correctly
kubectl get secret test-sops-secret -o jsonpath='{.data.username}' | base64 -d
# Should output: admin

# Check pod logs
kubectl logs sops-test-pod
```

## Test Scenarios

### Scenario 1: Basic Encryption/Decryption
- Encrypt a secret with SOPS
- Decrypt it manually to verify
- Status: ✅ (completed during setup)

### Scenario 2: Manual kubectl Deployment
- Apply the encrypted secret using kubectl + SOPS
- Verify pod can access the decrypted values
- Tests: Local SOPS setup works

### Scenario 3: ArgoCD Sync
- Push encrypted manifests to Git
- Let ArgoCD sync and deploy
- Verify ArgoCD can decrypt and apply secrets
- Tests: ArgoCD SOPS integration works end-to-end

### Scenario 4: Update Secret
```bash
# Edit the plain secret
vim manifests/test-secret.yaml

# Re-encrypt
sops --encrypt manifests/test-secret.yaml > encrypted/test-secret.enc.yaml

# Commit and push
git add encrypted/test-secret.enc.yaml
git commit -m "Update secret"
git push

# ArgoCD should automatically detect and sync the change
argocd app sync sops-test-app
```

## Troubleshooting

### ArgoCD Can't Decrypt Secrets

1. Check if GPG key is properly imported:
```bash
kubectl exec -n argocd deploy/argocd-repo-server -- gpg --list-secret-keys
```

2. Check ArgoCD logs:
```bash
kubectl logs -n argocd deploy/argocd-repo-server
```

3. Verify SOPS plugin is installed:
```bash
kubectl exec -n argocd deploy/argocd-repo-server -- sops --version
```

### Secret Not Decrypted in Cluster

1. Verify the secret exists:
```bash
kubectl get secret test-sops-secret -o yaml
```

2. Check if the secret is still encrypted (it should be decrypted):
```bash
kubectl get secret test-sops-secret -o jsonpath='{.data.username}' | base64 -d
```

### Pod Can't Access Secret Values

1. Check pod status:
```bash
kubectl describe pod sops-test-pod
```

2. Verify secret keys match:
```bash
kubectl get secret test-sops-secret -o jsonpath='{.data}' | jq
```

## Cleanup

```bash
# Delete ArgoCD application
kubectl delete -f argocd-application.yaml
# or
argocd app delete sops-test-app

# Manually delete resources if needed
kubectl delete pod sops-test-pod
kubectl delete secret test-sops-secret
kubectl delete configmap test-sops-configmap
```

## Additional Resources

- [SOPS Documentation](https://github.com/mozilla/sops)
- [ArgoCD SOPS Integration](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/)
- [Kustomize with SOPS](https://github.com/viaduct-ai/kustomize-sops)

## Notes

- The plain secret in `manifests/test-secret.yaml` is kept for reference and re-encryption purposes
- Never commit unencrypted secrets to Git (only commit files in `encrypted/`)
- The `.sops.yaml` file ensures consistent encryption across all team members
- Consider using age encryption instead of GPG for better performance and simpler key management

#!/bin/bash
# Quick test commands for SOPS + ArgoCD integration

set -e

echo "=== SOPS + ArgoCD Test Commands ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test 1: Verify SOPS can decrypt
echo -e "${YELLOW}Test 1: Decrypt secret with SOPS${NC}"
if sops -d encrypted/test-secret.enc.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✓ SOPS decryption works${NC}"
else
    echo -e "${RED}✗ SOPS decryption failed${NC}"
    exit 1
fi
echo ""

# Test 2: Show decrypted content
echo -e "${YELLOW}Test 2: Show decrypted secret content${NC}"
sops -d encrypted/test-secret.enc.yaml
echo ""

# Test 3: Apply with kubectl (manual)
echo -e "${YELLOW}Test 3: Deploy with kubectl (manual test)${NC}"
read -p "Deploy test resources to cluster? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sops -d encrypted/test-secret.enc.yaml | kubectl apply -f -
    kubectl apply -f manifests/test-configmap.yaml
    kubectl apply -f manifests/test-pod.yaml

    echo -e "${GREEN}✓ Resources deployed${NC}"
    echo "Waiting for pod to start..."
    kubectl wait --for=condition=Ready pod/sops-test-pod --timeout=60s || true

    echo ""
    echo -e "${YELLOW}Pod logs:${NC}"
    kubectl logs sops-test-pod || echo "Pod not ready yet, try: kubectl logs sops-test-pod"
    echo ""

    echo -e "${YELLOW}Cleanup? (y/N)${NC}"
    read -p "" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete pod sops-test-pod --ignore-not-found=true
        kubectl delete secret test-sops-secret --ignore-not-found=true
        kubectl delete configmap test-sops-configmap --ignore-not-found=true
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    fi
fi
echo ""

# Test 4: Verify ArgoCD GPG key
echo -e "${YELLOW}Test 4: Check ArgoCD GPG configuration${NC}"
read -p "Check ArgoCD repo-server GPG keys? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "GPG keys in ArgoCD repo-server:"
    kubectl exec -n argocd deploy/argocd-repo-server -- gpg --list-secret-keys || \
        echo -e "${RED}✗ Could not access ArgoCD repo-server${NC}"
fi
echo ""

# Test 5: Deploy ArgoCD Application
echo -e "${YELLOW}Test 5: Deploy ArgoCD Application${NC}"
echo "Note: Update argocd-application.yaml with your Git repo URL first!"
read -p "Deploy ArgoCD application? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl apply -f argocd-application.yaml
    echo -e "${GREEN}✓ ArgoCD application created${NC}"
    echo ""
    echo "Check status with:"
    echo "  kubectl get applications -n argocd"
    echo "  argocd app get sops-test-app"
fi
echo ""

echo -e "${GREEN}=== Tests complete ===${NC}"

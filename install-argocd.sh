#!/bin/bash

# Create the Argo CD namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
kubectl rollout status deploy/argocd-server -n argocd

echo "Argo CD has been installed. Visit https://argoproj.github.io/argo-cd/getting_started/ for next steps."

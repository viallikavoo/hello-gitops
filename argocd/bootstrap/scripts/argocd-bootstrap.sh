#!/bin/bash
set -e
set -o pipefail
APP_SET_FOLDER=$GITHUB_WORKSPACE/argocd/appset-resources
GEN_FOLDER=$GITHUB_WORKSPACE/argocd/generated-resources

#Create ArgoCD App
argocd app create -f $GEN_FOLDER/$appName-application.yaml --auth-token $GITOPS_ARGOCD_TOKEN --server localhost:8080 --insecure --upsert

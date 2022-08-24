#!/bin/bash
set -e
set -o pipefail
APP_SET_FOLDER=$GITHUB_WORKSPACE/argocd/appset-resources
GEN_FOLDER=$GITHUB_WORKSPACE/argocd/generated-resources
KUSTOMIZE_BASE_FOLDER=$GITHUB_WORKSPACE/kustomize/base
KUSTOMIZE_OVERLAYS_FOLDER=$GITHUB_WORKSPACE/kustomize/overlays
ENVIRONMENTS=("stag")
export BASE=$(git branch --show-current)

mkdir -p $APP_SET_FOLDER $GEN_FOLDER $KUSTOMIZE_BASE_FOLDER

for env in ${ENVIRONMENTS[@]}; do
    mkdir -p $KUSTOMIZE_OVERLAYS_FOLDER/$env
    cp $GITHUB_WORKSPACE/argocd/bootstrap/templates/kustomize/overlays/$env/kustomization.yaml $KUSTOMIZE_OVERLAYS_FOLDER/$env/
    yq e '
      .metadata.name = strenv(appName) |
      .metadata.labels.app = strenv(appName) |
      .spec.selector.matchLabels.app = strenv(appName) |
      .spec.template.metadata.labels.app = strenv(appName) |
      .spec.template.spec.containers[0].image = strenv(appName) |
      .spec.template.spec.containers[0].name = strenv(appName) |
      .spec.template.spec.imagePullSecrets[0].name = "dockerconfigjson-github-com"
    ' $GITHUB_WORKSPACE/argocd/bootstrap/templates/kustomize/overlays/${env}/deployment.yaml > $KUSTOMIZE_OVERLAYS_FOLDER/$env/deployment.yaml

    yq e '
      .images[0].name = strenv(appName) |
      .images[0].newName = strenv(registry)+"/"+strenv(appName)
    ' $GITHUB_WORKSPACE/argocd/bootstrap/templates/kustomize/overlays/${env}/kustomization.yaml > $KUSTOMIZE_OVERLAYS_FOLDER/$env/kustomization.yaml

done

yq e '
  .metadata.name = strenv(appName) |
  .spec.project = strenv(namespace) |
  .spec.source.repoURL = strenv(repoURL) |
  .spec.source.targetRevision = strenv(BASE) |
  .spec.destination.namespace = strenv(namespace)
' $GITHUB_WORKSPACE/argocd/bootstrap/templates/template-application.yaml > $GEN_FOLDER/$appName-application.yaml

yq e '
  .metadata.name = strenv(appName) |
  .spec.template.metadata.name = strenv(appName)+"-{{cluster}}" |
  .spec.template.spec.project = strenv(namespace) |
  .spec.template.spec.source.repoURL = strenv(repoURL) |
  .spec.template.spec.source.targetRevision = strenv(BASE) |
  .spec.template.spec.destination.namespace = strenv(namespace)
' $GITHUB_WORKSPACE/argocd/bootstrap/templates/template-applicationset.yaml > $APP_SET_FOLDER/$appName-applicationset.yaml




yq e '
  .metadata.name = strenv(appName) |
  .metadata.labels.app = strenv(appName) |
  .spec.selector.app = strenv(appName)
' $GITHUB_WORKSPACE/argocd/bootstrap/templates/kustomize/base/service.yaml > $KUSTOMIZE_BASE_FOLDER/service.yaml

cp $GITHUB_WORKSPACE/argocd/bootstrap/templates/kustomize/base/kustomization.yaml > $KUSTOMIZE_BASE_FOLDER/kustomization.yaml


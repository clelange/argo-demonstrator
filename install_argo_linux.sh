#!/bin/bash
ARGO_VERSION=2.1.1
HELM_VERSION=2.9.1
echo "Getting argo ${ARGO_VERSION}"
curl -sSL -o ~/bin/argo https://github.com/argoproj/argo/releases/download/v${ARGO_VERSION}/argo-linux-amd64
chmod +x ~/bin/argo
echo "Getting helm ${HELM_VERSION}"
curl -sSL -O https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz
tar xzf helm-v${HELM_VERSION}-linux-amd64.tar.gz
rm helm-v${HELM_VERSION}-linux-amd64.tar.gz
cp linux-amd64/helm ~/bin/
chmod +x ~/bin/helm
rm -r linux-amd64
echo "Initialising helm"
helm init --upgrade
echo "Installing argo"
argo install
echo "done"

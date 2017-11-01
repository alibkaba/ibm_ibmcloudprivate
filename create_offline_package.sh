#!/bin/bash
# Modified version of https://developer.ibm.com/recipes/tutorials/installing-ibm-cloud-privatece-in-offline-mode/
# This script will only work for x86_64.

# list of all containers:version believed to be needed to get icp ce 2.1.0 up and running
IMAGES=(
ibmcom/icp-inception:2.1.0
ibmcom/icp-identity-manager:2.1.0
ibmcom/icp-datastore:2.1.0
ibmcom/icp-identity-provider:2.1.0
ibmcom/iam-token-service:2.1.0
ibmcom/icp-platform-auth:2.1.0
ibmcom/icp-catalog-ui:2.1.0
ibmcom/icp-platform-api:2.1.0
ibmcom/icp-platform-ui:2.1.0
ibmcom/icp-router:2.1.0
ibmcom/unified-router:2.1.0
ibmcom/icp-image-manager:2.1.0
ibmcom/icp-helm-api:2.1.0
ibmcom/icp-helm-repo:2.1.0
ibmcom/iam-policy-decision:2.1.0
ibmcom/iam-policy-administration:2.1.0
ibmcom/metering-reader:2.1.0
ibmcom/rescheduler:v0.5.2
ibmcom/tiller:v2.6.0
ibmcom/kubernetes:v1.7.3
ibmcom/calico-policy-controller:v0.7.0
ibmcom/service-catalog-apiserver:v0.0.15
ibmcom/service-catalog-controller-manager:v0.0.15
ibmcom/calico-node:v2.4.1
ibmcom/calico-ctl:v1.4.0
ibmcom/calico-cni:v1.10.0
ibmcom/filebeat:5.5.1
ibmcom/heapster:v1.4.0
ibmcom/k8s-dns-sidecar:1.14.4
ibmcom/k8s-dns-kube-dns:1.14.4
ibmcom/k8s-dns-dnsmasq-nanny:1.14.4
ibmcom/etcd:v3.1.5
ibmcom/node-exporter:v0.14.0
ibmcom/mariadb:10.1.16
ibmcom/registry:2
ibmcom/pause:3.0
)

###############################################
# x86_64 Package
###############################################
function create_x86_64_package() {
  local images="";
  # docker pulls all container images one by one and appends each container name into 'images'
  for image in ${IMAGES[@]}; do
    docker pull $image;
    images="$images $image"
  done

  echo -e "\nGenerating x86_64 offline package, this may take a while.\n"

  # save all appended container names within images into a .tar
  docker save -o ICP-CE-x86_64-2.1.0.tar $images;

  # compress it into gz
  tar zcf ICP-CE-x86_64-2.1.0.tar.gz ICP-CE-x86_64-2.1.0.tar;

  # delete the .tar file
  rm -f ICP-CE-x86_64-2.1.0.tar;
}

create_x86_64_package;

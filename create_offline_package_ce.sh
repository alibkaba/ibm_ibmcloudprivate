#!/bin/bash
###############################################################################################################
## [Author]:
## Rebecca Guo
## modified by Ali Kaba (https://github.ibm.com/akaba/icp) (https://github.com/AKx2f/icp)
##-------------------------------------------------------------------------------------------------------------
## [Details]:
## This will bundle all ICP CE images into a .tar.gz file to do an offline installation elsewhere.
##-------------------------------------------------------------------------------------------------------------
## [Warning]:
## This script comes as-is with no promise of functionality or accuracy.  Feel free to change or improve it
## any way you see fit.
## Debian distribution / AMD64 only / Ubuntu 16.04 LTS
##-------------------------------------------------------------------------------------------------------------
## [Modification, Distribution, and Attribution]:
## You are free to modify and/or distribute this script as you wish.  I only ask that you maintain original
## author attribution and not attempt to sell it or incorporate it into any commercial offering (as if it's
## worth anything anyway :)
###############################################################################################################
# This script will only work for x86_64.

# list of all containers:version believed to be needed to get icp ce 2.1.0 up and running
IMAGES=(
ibmcom/alertmanager:v0.8.0
ibmcom/calico-cni:v1.10.0
ibmcom/calico-ctl:v1.4.0
ibmcom/calico-node:v2.4.1
ibmcom/calico-policy-controller:v0.7.0
ibmcom/icp-catalog-ui:2.1.0
ibmcom/icp-datastore:2.1.0
ibmcom/collectd-exporter:0.3.1
ibmcom/configmap-reload:v0.1
ibmcom/coredns:010
ibmcom/curl:3.6
ibmcom/defaultbackend:1.2
ibmcom/elasticsearch:5.5.1
ibmcom/etcd:v3.1.5
ibmcom/filebeat:5.5.1
ibmcom/gluster:0.5
ibmcom/grafana:4.4.3
ibmcom/heapster:v1.4.0
ibmcom/heketi:5
ibmcom/icp-helm-api:2.1.0
ibmcom/icp-helm-repo:2.1.0
ibmcom/icp-initcontainer:1.0.0
ibmcom/icp-image-manager:2.1.0
ibmcom/registry:2
ibmcom/icp-inception:2.1.0
ibmcom/kubernetes:v1.7.3
ibmcom/pause:3.0
ibmcom/kibana:5.5.1
ibmcom/kube-state-metrics:v1.0.0
ibmcom/k8s-dns-dnsmasq-nanny:1.14.4
ibmcom/k8s-dns-kube-dns:1.14.4
ibmcom/k8s-dns-sidecar:1.14.4
ibmcom/logstash:5.5.1
ibmcom/mariadb:10.1.16
ibmcom/metering-data-manager:2.1.0
ibmcom/metering-reader:2.1.0
ibmcom/metering-server:2.1.0
ibmcom/metering-ui:2.1.0
ibmcom/nginx-ingress-controller:0.9.0-beta.12
ibmcom/node-exporter:v0.14.0
ibmcom/icp-platform-api:2.1.0
ibmcom/iam-token-service:2.1.0
ibmcom/iam-policy-administration:2.1.0
ibmcom/iam-policy-decision:2.1.0
ibmcom/icp-identity-manager:2.1.0
ibmcom/icp-identity-provider:2.1.0
ibmcom/icp-platform-ui:2.1.0
ibmcom/prometheus:v1.7.1
ibmcom/rescheduler:v0.5.2
ibmcom/icp-router:2.1.0
ibmcom/service-catalog-apiserver:v0.0.15
ibmcom/service-catalog-controller-manager:v0.0.15
ibmcom/tiller:v2.6.0
ibmcom/ucarp:1.5.2
ibmcom/unified-router:2.1.0
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

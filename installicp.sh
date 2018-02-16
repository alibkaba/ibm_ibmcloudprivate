#!/bin/bash
###############################################################################################################
## [Author]:
## Ali Kaba (https://github.ibm.com/akaba/icp) (https://github.com/alibkaba/icp) @alibkaba
##-------------------------------------------------------------------------------------------------------------
## [Details]:
## ICP CE/EE
##
## Tested on:
## Linux™ 64-bit Ubuntu 16.04 LTS
## Linux on POWER 64-bit Little Endian (LE) Ubuntu 16.04 LTS
##-------------------------------------------------------------------------------------------------------------
## [Warning]:
## IBM does not endorse this script in any shape or form.
## This script comes as-is with no promise of functionality or accuracy.
##-------------------------------------------------------------------------------------------------------------
## [Modification, Distribution, and Attribution]:
## You are free to modify and/or distribute this script as you wish.  I only ask that you maintain original
## author attribution and not attempt to sell it or incorporate it into any commercial offering (as if it's
###############################################################################################################
# To do list
## dependenciesINSTALL
### check if ssh allows remote login (and as root)
### update Network Time Protocol apt-get install -y ntp, sytemctl restart ntp, test with ntpq -p

## upgrade & downgrade

## troubleshooting

### check all listening ports
### is ssh enabled
### can you remote into ssh

# fonts formatting
RESET='\e[0m'; # No Color
RED='\e[31m';
LGREEN='\e[92m';
LYELLOW='\e[93m';
LCYAN='\e[96m';
BLINK='\e[5m';
BOLD='\e[1m';

if [[ "${EUID}" -ne 0 ]]; then
 echo -e "${RED}[-]${RESET} This script must be run as ${RED}root${RESET}";
 echo -e "[-] This script must be run as root";
 sleep 2;
 exit 1;
fi

envCHKpt(){
  # architecture
  arch=$(uname -m);
  if [[ "$arch" == "x86_64" ]]; then
    arch="x86_64";
  elif [[ "$arch" == "ppc64le" ]]; then
    arch="ppc64le";
  else
    echo -e "${RED}[-] Unknown or unsupported system arch: `uname -m`.${RESET}";
    exit 1;
  fi

	# distribution check
  if grep -iq 'ubuntu' /etc/*-release; then
    distro="ubuntu";
    cmd="apt-get"
  elif grep -iq 'red hat\|rhel' /etc/*-release; then
    distro="rhel";
    cmd="apt-get"
  else
    echo -e "${RED}[-] This script only works for Ubuntu and Red Hat distribution.${RESET}";
    exitSCRIPT;
  fi

  cmd=
  startCHKpt;
}

startCHKpt(){
  echo -e "\n${RESET}########################################################################################";
  echo -e "############################## Install IBM Cloud Private  ##############################";
  echo -e "####################################### Jan 2018 #######################################";
  echo -e "Use it at your own ${RED}${BOLD}${BLINK}risk${RESET}! :)";
  echo -e "Tested on:";
  echo -e "Linux 64-bit Ubuntu 16.04 LTS";
  echo -e "Linux on POWER 64-bit Little Endian (LE) Ubuntu 16.04 LTS";
  echo -e "\n${LCYAN}Choose${RESET} an option:\n";
	options=("Install Docker CE (Ubuntu only)" "Install Dependencies" "Install ICP CE" "Install ICP EE" "Deploy ICP CE" "Deploy ICP EE" "Uninstall ICP CE" "Uninstall ICP EE" "Upgrades (Apr 2018)" "Diagnose (see icptools.sh)" "Create Offline CE Package" "Exit")
  COLUMNS=12;
	select opt in "${options[@]}";
  do
		case $opt in
      "Install Docker CE (Ubuntu only)")
        installDOCKERce;
        ;;
			"Install Dependencies")
				installDEPENDENCIES;
				;;
      "Install ICP CE")
        export icpEDITION="ce";
        installSOURCE;
        installICPce;
        ;;
      "Install ICP EE")
        export icpEDITION="ee";
        installSOURCE;
        installICPee;
        ;;
      "Deploy ICP CE")
        export icpEDITION="ce";
        deployCHKpt;
        ;;
      "Deploy ICP EE")
        export icpEDITION="ee";
        deployCHKpt;
        ;;
      "Uninstall ICP CE")
  			uninstallICPce;
  			;;
      "Uninstall ICP EE")
        uninstallICPee;
        ;;
      "Upgrades (Apr 2018)")
        echo "Coming soon!";
        ;;
      "Diagnose (see icptools.sh)")
        echo "see icptools.sh!";
        ;;
      "Create Offline CE Package")
        createOFFLINEcePKG;
        ;;
      "Exit")
    		exitSCRIPT;
        ;;
			*)
				echo invalid option;
				;;
		esac
	done
}

installSOURCE(){
  if [ ! -f install.conf ];then
    echo -e "${RED}[-] Please download and configure the install.conf file in this directory.${RESET}";
    exitSCRIPT;
  fi
  source install.conf
  IFS=$'\n';
  masterARRAY=($(grep "^[^#;]" install.conf | sed -n '/master]/,/worker/{/master]/!{/worker/!p}}';));
  workerARRAY=($(grep "^[^#;]" install.conf | sed -n '/worker]/,/proxy/{/worker]/!{/proxy/!p}}';));
  proxyARRAY=($(grep "^[^#;]" install.conf | sed -n '/proxy]/,/management/{/proxy]/!{/management/!p}}';));
  managementARRAY=($(grep "^[^#;]" install.conf | sed -n '/management]/,/end/{/management]/!{/end/!p}}';));
}

installDOCKERce(){
  # uninstall old versions of docker
	echo -e "${LGREEN}[+] Uninstalling old Docker versions${LYELLOW}";
  apt-get -y remove docker docker-engine docker.io

  sleep 2;

	# update apt-get
	echo -e "${LGREEN}[+] Updating the apt package index${LYELLOW}";
	apt-get -y update

  sleep 2;

	# install packages to allow apt to use a repository over HTTPS
	echo -e "${LGREEN}[+] Installing packages to allow apt to use a repository over HTTPS${LYELLOW}";
	apt-get -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common;

  sleep 2;

	# add Docker’s official GPG key
	echo -e "${LGREEN}[+] Adding Docker’s official GPG key.${LYELLOW}";
	curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -;

  sleep 2;

  # verify Docker’s official GPG key
  if [[ "Key fingerprint = 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88" == $(apt-key fingerprint 0EBFCD88 | awk '/fingerprint/ {print $0}' | sed -e 's/^[ \t]*//') ]]; then
    echo -e "${LGREEN}[+] Valid Docker GPG key (9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88).";
  else
    echo -e "${RED}[-] Invalid Docker GPG key (9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88).${RESET}";
    exitSCRIPT;
  fi

  sleep 2;

	# setup a stable docker repository
	echo -e "${LGREEN}[+] Setting up the stable repository.${LYELLOW}";
  if [ "$arch" == "x86_64" ]; then
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable";
  elif [ "$arch" == "ppc64le" ]; then
    add-apt-repository "deb [arch=ppc64el] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable";
  else
    echo -e "${RED}[-] Setting up a stable repo for Docker failed.${RESET}";
  fi

  sleep 2;

	# update apt-get
	echo -e "${LGREEN}[+] Updating the apt package index.${LYELLOW}";
	apt-get -y update;

  sleep 2;

	# install docker-ce
	echo -e "${LGREEN}[+] Installing docker-ce.${LYELLOW}";
	apt-get -y install docker-ce;

  startCHKpt;
}

installDEPENDENCIES(){
  # install openssh-server
  if ! dpkg-query -W -f='${Status}' openssh-server 2>/dev/null | grep -q "ok installed"; then
    echo -e "${LGREEN}[+] Downloading and installing openssh-server.${LYELLOW}";
    apt-get install -y openssh-server;
  else
    echo -e "${LGREEN}[+] openssh-server is already installed!";
  fi

  sleep 2;

  # install python
  if ! dpkg-query -W -f='${Status}' python 2>/dev/null | grep -q "ok installed"; then
    echo -e "${LGREEN}[+] Downloading and installing python.${LYELLOW}";
    apt-get -y install python;
  else
    echo -e "${LGREEN}[+] python is already installed!";
  fi

  sleep 2;

  # install python-pip
  if ! dpkg-query -W -f='${Status}' python-pip 2>/dev/null | grep -q "ok installed"; then
    echo -e "${LGREEN}[+] Downloading and installing python-pip.${LYELLOW}";
    apt-get -y install python-pip;
  else
    echo -e "${LGREEN}[+] python-pip is already installed!";
  fi

  sleep 2;

  # install kubectl
  if ! which kubectl &>/dev/null; then
    echo -e "${LGREEN}[+] Installing kubectl.${LYELLOW}";
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl;
    chmod +x ./kubectl;
    mv ./kubectl /usr/local/bin/kubectl;
  else
    echo -e "${LGREEN}[+] kubectl is already installed!";
  fi


  sleep 2;

  # install glusterfs-client
  echo -e "${LGREEN}[+] Installing glusterfs-client and setting up dm_thin_pool.${LYELLOW}";
  apt-get -y install glusterfs-client;
  modprobe dm_thin_pool;
  echo dm_thin_pool | sudo tee -a /etc/modules;

  sleep 2;

  # add a parameter (vm.max_map_count=262144) in /etc/sysctl.conf
  if ! cat /etc/sysctl.conf | grep "^[^#;]" | grep -q vm.max_map_count; then
    echo -e "${LGREEN}[+] Configuring Virtual Memory settings.${LYELLOW}";
    sysctl -w vm.max_map_count=262144;
    echo -e "vm.max_map_count=262144" >> /etc/sysctl.conf;
  else
    if grep "^[^#;]" /etc/sysctl.conf | grep vm.max_map_count | awk -F "=" '{ print $2 }' | egrep -q '^[0-9]+$'; then
      if (($(grep "^[^#;]" /etc/sysctl.conf | grep vm.max_map_count | awk -F "=" '{ print $2 }') >= 262144)); then
        echo -e "${LGREEN}[+] /etc/sysctl.conf's vm.max_map_count has the minumum required value of 262144.${LYELLOW}";
      else
        echo -e "${LGREEN}[+] /etc/sysctl.conf's vm.max_map_count value was updated to 262144.${LYELLOW}";
        sed -i -e 's/'$(grep vm.max_map_count /etc/sysctl.conf | awk -F "=" '{ print $2 }')'/262144/g' /etc/sysctl.conf;
      fi
    else
      echo -e "${RED}[-] /etc/sysctl.conf's vm.max_map_count value contains non-integer.  Please remove vm.max_map_count and re-run the script.${RESET}";
    fi
  fi

  echo -e "${RESET}"

  startCHKpt;
}

installICPce(){
  # dependencies for both ce and ee
  install1;

  sleep 2;

  # pull icp from docker
	echo -e "${LGREEN}[+] Pulling ICP CE from Docker Hub.${LYELLOW}";
	docker pull $icpCE;

  sleep 2;

  # extract icp config files
  if [[ ! -d /opt/icp/cluster ]]; then
    echo -e "${LGREEN}[+] Extracting ICP's configuration files.${RESET}";
    docker run -e LICENSE=accept -v /opt/icp:/data $icpCE cp -r cluster /data;
  else
    echo -e "${LGREEN}[+] ICP has already been extracted!";
  fi

  sleep 2;

  # dependencies for both ce and ee
  install2;

  sleep 2;

  deployCHKpt;
}

installICPee(){
  # installs for both ce and ee
  install1;

  sleep 2;

  # find icp
  if [ -f $icpEEtar ];then
    echo -e "${LGREEN}[+] "$icpEEtar" exists!";
  else
    echo -e "${RED}[-] Please download "$icpEEtar" in this directory.${RESET}";
    exitSCRIPT;
  fi

  sleep 2;

  # unzip icp from docker
  echo -e "${LGREEN}[+] Extracting ICP.${LYELLOW}";
  tar xf $icpEEtar -O | sudo docker load

  sleep 2;

  # extract icp config files
  if [[ ! -d /opt/icp/cluster ]]; then
    echo -e "${LGREEN}[+] Extracting ICP's configuration files.${RESET}";
    docker run -e LICENSE=accept -v /opt/icp:/data $icpEE cp -r cluster /data;
  else
    echo -e "${LGREEN}[+] ICP has already been extracted!";
  fi

  sleep 2;

  # installs for both ce and ee
  install2;

  sleep 2;

  # create the image directory
  if [[ ! -d /opt/icp/cluster/images ]]; then
    echo -e "${LGREEN}[+] Creating the image directory in /opt/icp/cluster/images.${LYELLOW}";
    mkdir /opt/icp/cluster/images;
  else
    echo -e "${LGREEN}[+] Directory /opt/icp/cluster/images already exists!";
  fi

  sleep 2;

  # Copy $icpEEtar to /opt/icp/cluster/images
  echo -e "${LGREEN}[+] Copying "$icpEEtar" to /opt/icp/cluster/images.${LYELLOW}";
  cp $icpEEtar /opt/icp/cluster/images/$icpEEtar;

  sleep 2;

  deployCHKpt;
}

install1(){
  # create a passwordless ssh key
  if [ ! -f ~/.ssh/master.id_rsa 2>/dev/null ] || cat ~/.ssh/master.id_rsa 2>/dev/null | grep ENCRYPTED; then
    echo -e "${LGREEN}[+] Generating passwordless ssh key.${LYELLOW}";
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N "";
  else
    echo -e "${LGREEN}[+] Passwordless ssh key already exists!${LYELLOW}";
  fi

  sleep 2;

  # add ssh into authorized keys
  if ! cat ~/.ssh/authorized_keys 2>/dev/null | grep -q "$(cat ~/.ssh/master.id_rsa.pub)"; then
    echo -e "${LGREEN}[+] Adding passwordless ssh key to authorized keys.${LYELLOW}";
    cat ~/.ssh/master.id_rsa.pub >> ~/.ssh/authorized_keys;
  else
    echo -e "${LGREEN}[+] SSH key already exists in authorized keys!${LYELLOW}";
  fi

  sleep 2;

  # remove 127.0.1.1 from /etc/hosts
  echo -e "${LGREEN}[+] Removing 127.0.1.1 from /etc/hosts if it exists.${LYELLOW}";
  sed -i '/127.0.1.1/d' /etc/hosts;

  sleep 2;

  # NEEDS TO BE REFACTORED
  # add hosts in /etc/hosts
  for i in "${masterARRAY[@]}"
  do
    if ! cat /etc/hosts | egrep -q "$(echo $i | awk '{ print $1 }')|$(echo $i | awk '{ print $2 }')"; then
      echo -e "${LGREEN}[+] Adding "$i" in /etc/hosts.${LYELLOW}";
      echo $i >> /etc/hosts;
    else
      echo -e "${LGREEN}[+] "$i" already exists in /etc/hosts!${LYELLOW}";
    fi
  done

  sleep 2;

  # NEEDS TO BE REFACTORED
  # add hosts in /etc/hosts
  for i in "${workerARRAY[@]}"
  do
    if ! cat /etc/hosts | egrep -q "$(echo $i | awk '{ print $1 }')|$(echo $i | awk '{ print $2 }')"; then
      echo -e "${LGREEN}[+] Adding "$i" in /etc/hosts.${LYELLOW}";
      echo $i >> /etc/hosts;
    else
      echo -e "${LGREEN}[+] "$i" already exists in /etc/hosts!${LYELLOW}";
    fi
  done

  sleep 2;

  # NEEDS TO BE REFACTORED
  # add hosts in /etc/hosts
  for i in "${proxyARRAY[@]}"
  do
    if ! cat /etc/hosts | egrep -q "$(echo $i | awk '{ print $1 }')|$(echo $i | awk '{ print $2 }')"; then
      echo -e "${LGREEN}[+] Adding "$i" in /etc/hosts.${LYELLOW}";
      echo $i >> /etc/hosts;
    else
      echo -e "${LGREEN}[+] "$i" already exists in /etc/hosts!${LYELLOW}";
    fi
  done

  sleep 2;

  # NEEDS TO BE REFACTORED
  # add hosts in /etc/hosts
  for i in "${managementARRAY[@]}"
  do
    if ! cat /etc/hosts | egrep -q "$(echo $i | awk '{ print $1 }')|$(echo $i | awk '{ print $2 }')"; then
      echo -e "${LGREEN}[+] Adding "$i" in /etc/hosts.${LYELLOW}";
      echo $i >> /etc/hosts;
    else
      echo -e "${LGREEN}[+] "$i" already exists in /etc/hosts!${LYELLOW}";
    fi
  done

  sleep 2;

  # create the installation directory
  if [[ ! -d /opt/icp ]]; then
    echo -e "${LGREEN}[+] Creating the installation directory in /opt/icp/.${LYELLOW}";
    mkdir /opt/icp;
  else
    echo -e "${LGREEN}[+] Directory /opt/icp/ already exists!";
  fi
}

install2(){
  # copy ssh and set permission to 400
  echo -e "${LGREEN}[+] Copying ssh keys and setting permission in /opt/icp/cluster/ssh_keys.${LYELLOW}";
  cp ~/.ssh/master.id_rsa /opt/icp/cluster/ssh_key;
  chmod 400 /opt/icp/cluster/ssh_key;

  sleep 2;

  # NEEDS TO BE REFACTORED
  # sending ssh rsa master nodes
  echo -e "${LGREEN}[+] Sending ssh keys to other nodes.${LYELLOW}";
  for i in "${masterARRAY[@]}"
  do
    ssh-copy-id -i ~/.ssh/master.id_rsa root@$(echo $i | awk '{ print $1 }');
  done

  sleep 2;

  # NEEDS TO BE REFACTORED
  # sending ssh rsa worker nodes
  for i in "${workerARRAY[@]}"
  do
    ssh-copy-id -i ~/.ssh/master.id_rsa root@$(echo $i | awk '{ print $1 }');
  done

  sleep 2;

  # NEEDS TO BE REFACTORED
  # sending ssh rsa proxy nodes
  for i in "${proxyARRAY[@]}"
  do
    ssh-copy-id -i ~/.ssh/master.id_rsa root@$(echo $i | awk '{ print $1 }');
  done

  sleep 2;

  # NEEDS TO BE REFACTORED
  # sending ssh rsa management nodes
  for i in "${managementARRAY[@]}"
  do
    ssh-copy-id -i ~/.ssh/master.id_rsa root@$(echo $i | awk '{ print $1 }');
  done

  # add ip address in /opt/icp/cluster/
  echo -e "${LGREEN}[+] Updating /opt/icp/cluster/hosts file.${LYELLOW}";
  grep "^[^#;]" install.conf | awk '/master/{flag=1} /end/{flag=0} flag' | awk '{ print $1 }' > /opt/icp/cluster/hosts;
}

deployICP(){
  # deploy icp
  echo -e "${LGREEN}[+] Deploying ICP.${RESET}";
  if [ "$icpEDITION" == "ce" ]; then
    docker run -e LICENSE=accept -e ANSIBLE_CALLBACK_WHITELIST=profile_tasks,timer --net=host -t -v /opt/icp/cluster:/installer/cluster $icpCE install -vvv | tee install.log;
  elif [ "$icpEDITION" == "ee" ]; then
    docker run -e LICENSE=accept -e ANSIBLE_CALLBACK_WHITELIST=profile_tasks,timer --net=host -t -v /opt/icp/cluster:/installer/cluster $icpEE install -vvv | tee install.log;
  else
    echo -e "${RED}[-] Seems like ICP CE or EE weren't selected...how did you get here?${RESET}";
    exitSCRIPT;
  fi
  echo -e "${RESET}"
  exitSCRIPT;
}

uninstallICPce(){
  # uninstall icp
  echo -e "${LGREEN}[+] Uninstalling ICP.${RESET}";
  docker run --rm -t -e LICENSE=accept --net=host -v /opt/icp/cluster:/installer/cluster $icpCE uninstall;

  # restart docker
  echo -e "${LGREEN}[+] Restarting Docker.${RESET}";
  service docker restart;
  echo -e "${LGREEN}[+] If you have other nodes, restart their Docker using this command: service docker restart.${RESET}";

  # delete the /opt/ibm and /opt/kubernetes directories
  echo -e "${LGREEN}[+] Deleting the /opt/ibm and /opt/kubernetes directories.${RESET}";
  rm -r /opt/ibm;
  rm -r /opt/kubernetes;

  exitSCRIPT;
}

uninstallICPee(){
  # uninstall icp
  echo -e "${LGREEN}[+] Uninstalling ICP.${RESET}";
  docker run --rm -t -e LICENSE=accept --net=host -v /opt/icp/cluster:/installer/cluster $icpEE uninstall;

  # restart docker
  echo -e "${LGREEN}[+] Restarting Docker.${RESET}";
  service docker restart;
  echo -e "${LGREEN}[+] If you have other nodes, restart their Docker using this command: service docker restart.${RESET}";

  # delete the /opt/ibm and /opt/kubernetes directories
  echo -e "${LGREEN}[+] Deleting the /opt/ibm and /opt/kubernetes directories.${RESET}";
  rm -r /opt/ibm;
  rm -r /opt/kubernetes;

  exitSCRIPT;
}

createOFFLINEcePKG(){
  # list of all containers:version believed to be needed to get icp ce 2.1.0 up and running
  x86_64_IMAGES=(
  ibmcom/indices-cleaner:0.2
  ibmcom/icp-platform-auth:2.1.0.1
  ibmcom/alertmanager:v0.8.0
  ibmcom/calico-cni:v1.10.0
  ibmcom/calico-ctl:v1.4.0
  ibmcom/calico-node:v2.4.1
  ibmcom/calico-policy-controller:v0.7.0
  ibmcom/icp-catalog-ui:2.1.0.1
  ibmcom/icp-datastore:2.1.0.1
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
  ibmcom/icp-helm-api:2.1.0.1
  ibmcom/icp-helm-repo:2.1.0.1
  ibmcom/icp-initcontainer:1.0.0
  ibmcom/icp-image-manager:2.1.0.1
  ibmcom/registry:2
  ibmcom/icp-inception:2.1.0.1
  ibmcom/kubernetes:v1.7.3
  ibmcom/pause:3.0
  ibmcom/kibana:5.5.1
  ibmcom/kube-state-metrics:v1.0.0
  ibmcom/k8s-dns-dnsmasq-nanny:1.14.4
  ibmcom/k8s-dns-kube-dns:1.14.4
  ibmcom/k8s-dns-sidecar:1.14.4
  ibmcom/logstash:5.5.1
  ibmcom/mariadb:10.1.16
  ibmcom/metering-data-manager:2.1.0.1
  ibmcom/metering-reader:2.1.0.1
  ibmcom/metering-server:2.1.0.1
  ibmcom/metering-ui:2.1.0.1
  ibmcom/nginx-ingress-controller:0.9.0-beta.12
  ibmcom/node-exporter:v0.14.0
  ibmcom/icp-platform-api:2.1.0.1
  ibmcom/iam-token-service:2.1.0.1
  ibmcom/iam-policy-administration:2.1.0.1
  ibmcom/iam-policy-decision:2.1.0.1
  ibmcom/icp-identity-manager:2.1.0.1
  ibmcom/icp-identity-provider:2.1.0.1
  ibmcom/icp-platform-ui:2.1.0.1
  ibmcom/prometheus:v1.7.1
  ibmcom/rescheduler:v0.5.2
  ibmcom/icp-router:2.1.0.1
  ibmcom/service-catalog-apiserver:v0.0.15
  ibmcom/service-catalog-controller-manager:v0.0.15
  ibmcom/tiller:v2.6.0
  ibmcom/ucarp:1.5.2
  ibmcom/unified-router:2.1.0.1
  )

  ppc64le_IMAGES=(
  ibmcom/indices-cleaner:0.2
  ibmcom/icp-platform-auth:2.1.0.1
  ibmcom/alertmanager:v0.8.0
  ibmcom/calico-cni:v1.10.0
  ibmcom/calico-ctl:v1.4.0
  ibmcom/calico-node:v2.4.1
  ibmcom/calico-policy-controller:v0.7.0
  ibmcom/icp-catalog-ui:2.1.0.1
  ibmcom/icp-datastore:2.1.0.1
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
  ibmcom/icp-helm-api:2.1.0.1
  ibmcom/icp-helm-repo:2.1.0.1
  ibmcom/icp-initcontainer:1.0.0
  ibmcom/icp-image-manager:2.1.0.1
  ibmcom/registry:2
  ibmcom/icp-inception:2.1.0.1
  ibmcom/kubernetes:v1.7.3
  ibmcom/pause:3.0
  ibmcom/kibana:5.5.1
  ibmcom/kube-state-metrics:v1.0.0
  ibmcom/k8s-dns-dnsmasq-nanny:1.14.4
  ibmcom/k8s-dns-kube-dns:1.14.4
  ibmcom/k8s-dns-sidecar:1.14.4
  ibmcom/logstash:5.5.1
  ibmcom/mariadb:10.1.16
  ibmcom/metering-data-manager:2.1.0.1
  ibmcom/metering-reader:2.1.0.1
  ibmcom/metering-server:2.1.0.1
  ibmcom/metering-ui:2.1.0.1
  ibmcom/nginx-ingress-controller:0.9.0-beta.12
  ibmcom/node-exporter:v0.14.0
  ibmcom/icp-platform-api:2.1.0.1
  ibmcom/iam-token-service:2.1.0.1
  ibmcom/iam-policy-administration:2.1.0.1
  ibmcom/iam-policy-decision:2.1.0.1
  ibmcom/icp-identity-manager:2.1.0.1
  ibmcom/icp-identity-provider:2.1.0.1
  ibmcom/icp-platform-ui:2.1.0.1
  ibmcom/prometheus:v1.7.1
  ibmcom/rescheduler:v0.5.2
  ibmcom/icp-router:2.1.0.1
  ibmcom/service-catalog-apiserver:v0.0.15
  ibmcom/service-catalog-controller-manager:v0.0.15
  ibmcom/tiller:v2.6.0
  ibmcom/ucarp:1.5.2
  ibmcom/unified-router:2.1.0.1
  )

  local images="";
  # docker pulls all container images one by one and appends each container name into 'images'
  if [[ "$arch" == "x86_64" ]]; then
    for image in ${x86_64_IMAGES[@]}; do
      docker pull $image;
      images="$images $image"
    done
  else
    for image in ${ppc64le_IMAGES[@]}; do
      docker pull $image;
      images="$images $image"
    done
  fi

  echo -e "\nGenerating x86_64 offline package, this may take a while.\n"

  # save all appended container names within images into a .tar
  docker save -o ICP-CE-$arch-2.1.0.1.tar $images;

  # compress it into gz
  tar zcf ICP-CE-$arch-2.1.0.1.tar.gz ICP-CE-$arch-2.1.0.1.tar;

  # delete the .tar file
  rm -f ICP-CE-$arch-2.1.0.1.tar;
}

deployCHKpt(){
	echo -e "\n\n${RESET}########################################################################################";
  echo -e "Verify things before deploying ICP from another ${RED}${BOLD}${BLINK}terminal${RESET}.";
	echo -e "Things like config.yaml, hosts, misc/storage_class, ssh_key, etc.";

  echo -e "\n${LCYAN}Choose${RESET} an option:\n";
	options=("Deploy ICP" "Back" "Exit")
	select opt in "${options[@]}";
	do
		case $opt in
			"Deploy ICP")
				deployICP;
				;;
      "Back")
  			startCHKpt;
  			;;
			"Exit")
				exitSCRIPT;
				;;
			*)
				echo invalid option;
				;;
		esac
	done
}

exitSCRIPT(){
  echo -e "${RESET}Exiting...";
  exit 0;
}

envCHKpt;

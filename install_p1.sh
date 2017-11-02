#!/bin/bash
###############################################################################################################
## [Author]: Ali Kaba (https://github.com/AKx2f/icp) (https://github.ibm.com/akaba/icp)
##-------------------------------------------------------------------------------------------------------------
## [Details]: ALL NODES INSTALL
## ICP CE/EE
## You want to run this script on all nodes.
##-------------------------------------------------------------------------------------------------------------
## [Warning]:
## IBM does not endorse this script in any shape or form.
## This script comes as-is with no promise of functionality or accuracy.  Feel free to change or improve it
## any way you see fit.
## Debian distribution / AMD64 only / Ubuntu 16.04 LTS
##-------------------------------------------------------------------------------------------------------------
## [Modification, Distribution, and Attribution]:
## You are free to modify and/or distribute this script as you wish.  I only ask that you maintain original
## author attribution and not attempt to sell it or incorporate it into any commercial offering (as if it's
## worth anything anyway :)
###############################################################################################################

# FONTS COLOR
RESET='\033[0m'; # No Color
RED='\033[0;31m';
LGREEN='\033[1;32m'
ORANGE='\033[0;33m';
LCYAN='\033[1;36m';

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root.  Do not use sudo, it will fail."
   exit 1
fi

install(){
  # uninstall old versions of docker
	echo -e "${LGREEN}[+] Uninstalling old Docker versions${ORANGE}";
  apt-get -y remove docker docker-engine docker.io

  sleep 2;

	# update apt-get
	echo -e "${LGREEN}[+] Updating the apt package index${ORANGE}";
	apt-get -y update

  sleep 2;

	# install packages to allow apt to use a repository over HTTPS
	echo -e "${LGREEN}[+] Installing packages to allow apt to use a repository over HTTPS${ORANGE}";
	apt-get -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common;

  sleep 2;

	# add Docker’s official GPG key
	echo -e "${LGREEN}[+] Adding Docker’s official GPG key${ORANGE}";
	curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -;

  sleep 2;

  # verify Docker’s official GPG key
  if [[ "Key fingerprint = 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88" == $(apt-key fingerprint 0EBFCD88 | awk '/fingerprint/ {print $0}' | sed -e 's/^[ \t]*//') ]]; then
    echo -e "${LGREEN}[+] Valid Docker GPG key (9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88)";
  else
    echo -e "${RED}[+] Invalid Docker GPG key (9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88)${RESET}";
    exit 0;
  fi

  sleep 2;

	# setup a stable docker repository
	echo -e "${LGREEN}[+] Setting up the stable repository${ORANGE}";
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  sleep 2;

	# update apt-get
	echo -e "${LGREEN}[+] Updating the apt package index${ORANGE}";
	apt-get -y update;

  sleep 2;

	# install docker-ce
	echo -e "${LGREEN}[+] Installing docker-ce${ORANGE}";
	apt-get -y install docker-ce;

  sleep 2;

  # install openssh-server
  if ! dpkg-query -W -f='${Status}' openssh-server 2>/dev/null | grep -q "ok installed"; then
    echo -e "${LGREEN}[+] Downloading and installing openssh-server.${ORANGE}";
    apt-get install -y openssh-server;
  else
    echo -e "${LGREEN}[+] openssh-server is already installed!";
  fi

  sleep 2;

  # install python
  if ! dpkg-query -W -f='${Status}' python 2>/dev/null | grep -q "ok installed"; then
    echo -e "${LGREEN}[+] Downloading and installing python.${ORANGE}";
    apt -y install python;
  else
    echo -e "${LGREEN}[+] python is already installed!";
  fi

  sleep 2;

  # install python-pip
  if ! dpkg-query -W -f='${Status}' python-pip 2>/dev/null | grep -q "ok installed"; then
    echo -e "${LGREEN}[+] Downloading and installing python-pip.${ORANGE}";
    apt-get -y install python-pip;
  else
    echo -e "${LGREEN}[+] python-pip is already installed!";
  fi

  sleep 2;

  # install kubectl
  echo -e "${LGREEN}[+] Installing kubectl.${ORANGE}";
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl;
  chmod +x ./kubectl;
  sudo mv ./kubectl /usr/local/bin/kubectl;

  sleep 2;

  # install glusterfs-client
  echo -e "${LGREEN}[+] Installing glusterfs-client and setting up dm_thin_pool.${ORANGE}";
  apt-get -y install glusterfs-client;
  modprobe dm_thin_pool;
  echo dm_thin_pool | sudo tee -a /etc/modules;

  sleep 2;

  # add a parameter (vm.max_map_count=262144) in /etc/sysctl.conf
  if ! cat /etc/sysctl.conf | grep "^[^#;]" | grep -q vm.max_map_count; then
    echo -e "${LGREEN}[+] Adding a vm.max_map_count=262144 in /etc/sysctl.conf.${ORANGE}";
    sysctl -w vm.max_map_count=262144;
    echo -e "vm.max_map_count=262144" >> /etc/sysctl.conf;
  else
    if grep "^[^#;]" /etc/sysctl.conf | grep vm.max_map_count | awk -F "=" '{ print $2 }' | egrep -q '^[0-9]+$'; then
      if (($(grep "^[^#;]" /etc/sysctl.conf | grep vm.max_map_count | awk -F "=" '{ print $2 }') >= 262144)); then
        echo -e "${LGREEN}[+] /etc/sysctl.conf's vm.max_map_count has the minumum required value of 262144.${ORANGE}";
      else
        echo -e "${LGREEN}[+] /etc/sysctl.conf's vm.max_map_count value was updated to 262144.${ORANGE}";
        sed -i -e 's/'$(grep vm.max_map_count /etc/sysctl.conf | awk -F "=" '{ print $2 }')'/262144/g' /etc/sysctl.conf;
      fi
    else
      echo -e "${RED}[!] /etc/sysctl.conf's vm.max_map_count value contains non-integer.  Please remove vm.max_map_count and re-run the script.${RESET}";
    fi
  fi

  echo -e "${RESET}"
  exit 0;
}

envCHECK(){
	# distribution check
	if cat /etc/*-release | grep -i "debian"; then
    start;
	else
    echo -e "${RED}[!] This script only works for Debian distribution${RESET}";
    exit 0;
	fi
}

start(){
	clear;
	echo -e "${RESET}########################################################################################";
  echo -e "Please read this script's description before running it.";
  echo -e "${RED}NOT${RESET} endorsed by IBM and so use it at your own ${RED}risk${RESET}.";
	echo -e "########################################################################################\n\n";

	echo -e "${RED}DO YOU WANT TO CONTINUE?${RESET} (type the number next to your option)";
	options=("yes" "no")
	select opt in "${options[@]}";
	do
		case $opt in
			"yes")
				install;
				;;
			"no")
				exit 0
				;;
			*)
				echo invalid option;
				;;
		esac
	done
}
envCHECK;

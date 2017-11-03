#!/bin/bash
###############################################################################################################
## [Author]:
## Ali Kaba (https://github.com/AKx2f/icp) (https://github.ibm.com/akaba/icp)
##-------------------------------------------------------------------------------------------------------------
## [Details]:
## Run this ICP EE uninstall script on the master/boot node.
##-------------------------------------------------------------------------------------------------------------
## [Required]:
## install.conf
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
source install.conf;

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

uninstall(){
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
}

envCHECK(){
	# distribution check
	if ! cat /etc/*-release | grep -i "debian"; then
		echo -e "${RED}[!] This script only works for Debian distribution.${RESET}";
		exit 0;
	else
		uninstall;
	fi
}
envCHECK;

#!/bin/bash
###############################################################################################################
## [Author]:
## Ali Kaba (https://github.com/AKx2f/icp) (https://github.ibm.com/akaba/icp)
##-------------------------------------------------------------------------------------------------------------
## [Details]:
## Run this ICP EE script on the master/boot node.
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

install(){
  # create a passwordless ssh key
  if [ ! -f ~/.ssh/master.id_rsa 2>/dev/null ] || cat ~/.ssh/master.id_rsa 2>/dev/null | grep ENCRYPTED; then
    echo -e "${LGREEN}[+] Generating passwordless ssh key.${ORANGE}";
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N "";
  else
    echo -e "${LGREEN}[+] Passwordless ssh key already exists!${ORANGE}";
  fi

  sleep 2;

  # add ssh into authorized keys
  if ! cat ~/.ssh/authorized_keys 2>/dev/null | grep -q "$(cat ~/.ssh/master.id_rsa.pub)"; then
    echo -e "${LGREEN}[+] Adding passwordless ssh key to authorized keys.${ORANGE}";
    cat ~/.ssh/master.id_rsa.pub >> ~/.ssh/authorized_keys;
  else
    echo -e "${LGREEN}[+] SSH key already exists in authorized keys!${ORANGE}";
  fi

  sleep 2;

  # remove 127.0.1.1 from /etc/hosts
  echo -e "${LGREEN}[+] Removing 127.0.1.1 from /etc/hosts if it exists.${ORANGE}";
  sed -i '/127.0.1.1/d' /etc/hosts;

  sleep 2;

  # NEEDS TO BE REFACTORED
  # add hosts in /etc/hosts
  for i in "${masterARRAY[@]}"
  do
    if ! cat /etc/hosts | egrep -q "$(echo $i | awk '{ print $1 }')|$(echo $i | awk '{ print $2 }')"; then
      echo -e "${LGREEN}[+] Adding "$i" in /etc/hosts.${ORANGE}";
      echo $i >> /etc/hosts;
    else
      echo -e "${LGREEN}[+] "$i" already exists in /etc/hosts!${ORANGE}";
    fi
  done

  sleep 2;

  # NEEDS TO BE REFACTORED
  # add hosts in /etc/hosts
  for i in "${workerARRAY[@]}"
  do
    if ! cat /etc/hosts | egrep -q "$(echo $i | awk '{ print $1 }')|$(echo $i | awk '{ print $2 }')"; then
      echo -e "${LGREEN}[+] Adding "$i" in /etc/hosts.${ORANGE}";
      echo $i >> /etc/hosts;
    else
      echo -e "${LGREEN}[+] "$i" already exists in /etc/hosts!${ORANGE}";
    fi
  done

  sleep 2;

  # NEEDS TO BE REFACTORED
  # add hosts in /etc/hosts
  for i in "${proxyARRAY[@]}"
  do
    if ! cat /etc/hosts | egrep -q "$(echo $i | awk '{ print $1 }')|$(echo $i | awk '{ print $2 }')"; then
      echo -e "${LGREEN}[+] Adding "$i" in /etc/hosts.${ORANGE}";
      echo $i >> /etc/hosts;
    else
      echo -e "${LGREEN}[+] "$i" already exists in /etc/hosts!${ORANGE}";
    fi
  done

  sleep 2;

  # NEEDS TO BE REFACTORED
  # add hosts in /etc/hosts
  for i in "${managementARRAY[@]}"
  do
    if ! cat /etc/hosts | egrep -q "$(echo $i | awk '{ print $1 }')|$(echo $i | awk '{ print $2 }')"; then
      echo -e "${LGREEN}[+] Adding "$i" in /etc/hosts.${ORANGE}";
      echo $i >> /etc/hosts;
    else
      echo -e "${LGREEN}[+] "$i" already exists in /etc/hosts!${ORANGE}";
    fi
  done

  sleep 2;

  # find icp
  if [ -f $icpEEtar ];then
    echo -e "${LGREEN}[+] "$icpEEtar" exists!";
  else
    echo -e "${RED}[+] Please download "$icpEEtar" in this directory.${RESET}";
    exit 0;
  fi

  sleep 2;

  # unzip icp from docker
	echo -e "${LGREEN}[+] Extracting ICP.${ORANGE}";
	tar xf $icpEEtar -O | sudo docker load

  sleep 2;

  # create the installation directory
  if [[ ! -d /opt/icp ]]; then
    echo -e "${LGREEN}[+] Creating the installation directory in /opt/icp/.${ORANGE}";
    mkdir /opt/icp;
  else
    echo -e "${LGREEN}[+] Directory /opt/icp/ already exists!";
  fi

  sleep 2;

  # extract icp config files
  if [[ ! -d /opt/icp/cluster ]]; then
    echo -e "${LGREEN}[+] Extracting ICP's configuration files.${RESET}";
    docker run -e LICENSE=accept -v /opt/icp:/data $icpEE cp -r cluster /data;
  else
    echo -e "${LGREEN}[+] ICP has already been extracted!";
  fi

  sleep 2;

  # copy ssh and set permission to 400
  echo -e "${LGREEN}[+] Copying ssh keys and setting permission in /opt/icp/cluster/ssh_keys.${ORANGE}";
  cp ~/.ssh/master.id_rsa /opt/icp/cluster/ssh_key;
  chmod 400 /opt/icp/cluster/ssh_key;

  sleep 2;

  # NEEDS TO BE REFACTORED
  # sending ssh rsa master nodes
  echo -e "${LGREEN}[+] Sending ssh keys to other nodes.${ORANGE}";
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

  sleep 2;

  # add ip address in /opt/icp/cluster/
  echo -e "${LGREEN}[+] Updating /opt/icp/cluster/hosts file.${ORANGE}";
  grep "^[^#;]" install.conf | awk '/master/{flag=1} /end/{flag=0} flag' | awk '{ print $1 }' > /opt/icp/cluster/hosts;

  # create the installation directory
  if [[ ! -d /opt/icp/images/ ]]; then
    echo -e "${LGREEN}[+] Creating the installation directory in /opt/icp/.${ORANGE}";
    mkdir /opt/icp/images;
  else
    echo -e "${LGREEN}[+] Directory /opt/icp/images already exists!";
  fi

  # Copy $icpEEtar to /opt/icp/cluster/images
  echo -e "${LGREEN}[+] Copying "$icpEEtar" to /opt/icp/cluster/images.${ORANGE}";
  mv $icpEEtar /opt/icp/cluster/images/$icpEEtar;

  finalCHECK;
}

deployICP(){
  # deploy icp
	echo -e "${LGREEN}[+] Deploying ICP.${RESET}";
	docker run -e LICENSE=accept --net=host -t -v /opt/icp/cluster:/installer/cluster $icpEE install | tee install.log
  echo -e "${RESET}"
  exit 0;
}

finalCHECK(){
	echo -e "${RESET}########################################################################################";
	echo -e "Please check any last minute configurations before ICP is deployed ${RED}in another terminal${RESET}.";
	echo -e "Things like config.yaml, hosts, misc/storage_class, ssh_key.";
	echo -e "########################################################################################\n\n";

  echo -e "${RED}DO YOU WANT TO CONTINUE?${RESET} (type 1 or 2)";
	options=("yes" "no")
	select opt in "${options[@]}";
	do
		case $opt in
			"yes")
				deployICP;
				;;
			"no")
				exit 0;
				;;
			*)
				echo invalid option;
				;;
		esac
	done
}

envCHECK(){
	# distribution check
	if ! cat /etc/*-release | grep -i "debian"; then
		echo -e "${RED}[!] This script only works for Debian distribution.${RESET}";
		exit 0;
	else
		start;
	fi
}

IFS=$'\n';
masterARRAY=($(grep "^[^#;]" install.conf | sed -n '/master]/,/worker/{/master]/!{/worker/!p}}';));
workerARRAY=($(grep "^[^#;]" install.conf | sed -n '/worker]/,/proxy/{/worker]/!{/proxy/!p}}';));
proxyARRAY=($(grep "^[^#;]" install.conf | sed -n '/proxy]/,/management/{/proxy]/!{/management/!p}}';));
managementARRAY=($(grep "^[^#;]" install.conf | sed -n '/management]/,/end/{/management]/!{/end/!p}}';));

start(){
	clear;
  echo -e "${RESET}########################################################################################";
  echo -e "Please read this script's description before running it.";
  echo -e "${RED}NOT${RESET} endorsed by IBM and so use it at your own ${RED}risk${RESET}.";
	echo -e "########################################################################################\n\n";

  echo -e "${RED}DO YOU WANT TO CONTINUE?${RESET} (type 1 or 2)";
	options=("yes" "no")
	select opt in "${options[@]}";
	do
		case $opt in
			"yes")
				install;
				;;
			"no")
				exit 0;
				;;
			*)
				echo invalid option;
				;;
		esac
	done
}
envCHECK;

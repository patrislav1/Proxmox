#!/bin/bash
set -e
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")

sshkey=$1
if [ -z "${sshkey}" ]; then
  echo "Please set SSHKEY as argument"
  exit 1
fi

while true; do
  read -p "This Will add the SSH key to All LXC Containers. Proceed(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done
clear
function header_info {
  echo -e "${BL}
  ____ ____  _   _ _  _________   __
 / ___/ ___|| | | | |/ / ____\ \ / /
 \___ \___ \| |_| | ' /|  _|  \ V / 
  ___) |__) |  _  | . \| |___  | |  
 |____/____/|_| |_|_|\_\_____| |_|  

${CL}"
}
header_info

containers=$(pct list | tail -n +2 | cut -f1 -d' ')

function add_sshkey_to_lxc() {
  container=$1
  clear
  header_info
  echo -e "${BL}[Info]${GN} Adding SSH key to${BL} $container ${CL} \n"
  authkeys="~/.ssh/authorized_keys"
  cmd=$(echo -e grep -q \"${sshkey}\" ${authkeys} \|\| mkdir -p ~/.ssh \&\& touch ${authkeys} \&\& echo \"${sshkey}\" \>\>${authkeys})
 # echo "${cmd}"
  pct exec $container -- bash -c "${cmd}"
}
read -p "Skip stopped containers? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  skip=no
else
  skip=yes
fi

for container in $containers; do
  status=$(pct status $container)
  if [ "$skip" == "no" ]; then
    if [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL} \n"
      pct start $container
      echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL} \n"
      sleep 5
      add_sshkey_to_lxc $container
      echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL} \n"
      pct shutdown $container &
    elif [ "$status" == "status: running" ]; then
      add_sshkey_to_lxc $container
    fi
  fi
  if [ "$skip" == "yes" ]; then
    if [ "$status" == "status: running" ]; then
      add_sshkey_to_lxc $container
    fi
  fi
done
wait

echo -e "${GN} Finished, SSH key added to all containers. ${CL} \n"

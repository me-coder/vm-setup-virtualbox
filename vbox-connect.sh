#!/bin/bash

VBOX=/c/Program\ Files/Oracle/VirtualBox
VM_NAME=$1
export VBOX
export VM_NAME

function check_status()
{
   # Keep trying until Guest IP is made available
   count=1
   while true; do
      echo "Acquiring guest IP..."
      while true; do         
         GUEST_IP=$("${VBOX}/VBoxManage.exe" guestproperty enumerate ${VM_NAME}|grep /VirtualBox/GuestInfo/Net/1/V4/IP|cut -d ',' -f 2|cut -d ':' -f 2|tr -d '[[:space:]]')
         if [ -n ${GUEST_IP} ];  then
            echo "IP of selected Guest: ${GUEST_IP}"
            break
         fi
         sleep 2
      done

      # Keep pinging until system is up and running
      tries=1
      while true; do
         echo "Attempt ${tries}: Trying to connect. Wait..."
         
         ping -n 1 ${GUEST_IP}>/dev/nul
         if [[ $? -eq 0 ]]; then
            return 0
         fi

         ((tries++)); sleep 2
         if [[ 3 -lt ${tries} ]]; then break; fi
      done
      
      echo "Retrying with a fresh IP..."
      ((count++)); sleep 5
      if [[ 3 -lt ${count} ]]; then return 1; fi
      
      unset GUEST_IP
      
   done
}

if [[ -z ${VM_NAME} ]]; then
   LIST=$("${VBOX}/VBoxManage.exe" list vms|cut -d' ' -f1|tr -d '"')
   LIST=(${LIST})
   
   i=0
   for vm in ${LIST[@]}; do
      echo $((i++)): $vm
   done

   read -p "Select VM: " RESPONSE
   
   VM_NAME=${LIST[$RESPONSE]}
fi

# Start if system is not running
if [[ "running" != $("${VBOX}/VBoxManage.exe" showvminfo ${VM_NAME} --details --machinereadable|grep 'VMState='|cut -d'=' -f2|tr -d '"') ]]; then
   "${VBOX}/VBoxManage.exe" startvm ${VM_NAME} --type headless
fi

check_status
ret_val=$?

# Connect when system is up
# echo
# read -p "Do you wish to ssh?(Y/n): " RESPONSE
# if [[ ${RESPONSE} = n ]]; then
  # exit
# else
   echo "Connecting to guest..."
   ssh root@${GUEST_IP}
# fi

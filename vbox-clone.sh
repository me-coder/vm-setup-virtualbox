#!/bin/sh

VM_NAME=$1
if [[ -z ${VM_NAME} ]]; then
  read "Specify VM name: " VM_NAME
fi
if [[ -z ${VM_NAME} ]]; then exit 1; fi

"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" --nologo clonevm vm-centos7 --mode machine --name ${VM_NAME} --basefolder "${HOME}/VirtualBox VMs" --register

# Delete shared drive folder if it exists
echo "Disconnecting shared drive."
"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" --nologo sharedfolder remove "${VM_NAME}" --name "share"
if [[ -d "${HOME}/VirtualBox VMs/${VM_NAME}/share" ]]; then
  rm -rf "${HOME}/VirtualBox VMs/${VM_NAME}/share"
fi

# Create a shared drive folder
if [[ ! -d "${HOME}/VirtualBox VMs/${VM_NAME}/share" ]]; then
  echo "Creating shared drive."
  mkdir -p "${HOME}/VirtualBox VMs/${VM_NAME}/share"
fi

# Register shared drive
echo "Registering shared drive."
"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" --nologo sharedfolder add "${VM_NAME}" --name "share" --hostpath "${HOME}/VirtualBox VMs/${VM_NAME}/share" --automount

# Copy files to shared drive
if [[ ! -d "${HOME}/VirtualBox VMs/${VM_NAME}/share/.ssh/" ]]; then
   mkdir -p "${HOME}/VirtualBox VMs/${VM_NAME}/share/.ssh/"
fi
cp "${HOME}/.ssh/id_rsa" "${HOME}/VirtualBox VMs/${VM_NAME}/share/.ssh/"
cp "${HOME}/.ssh/id_rsa.pub" "${HOME}/VirtualBox VMs/${VM_NAME}/share/.ssh/"
cat "${HOME}/VirtualBox VMs/vagrant-centos7/share/.ssh/id_rsa.pub">"${HOME}/VirtualBox VMs/${VM_NAME}/share/authorized_keys"

cp "${HOME}/.vimrc" "${HOME}/VirtualBox VMs/${VM_NAME}/share"
cp "${HOME}/Google Drive/vm/vbox-provisioner.sh" "${HOME}/VirtualBox VMs/${VM_NAME}/share"

echo "Starting VM for the first time, it may take long..."
"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" --nologo startvm ${VM_NAME} --type headless

sleep 15

# Connect to the new VM
# Unable to create directory or copy files to VM at the moment
"${HOME}/$(dirname "$0")/vbox-connect.sh" ${VM_NAME}

"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" --nologo controlvm ${VM_NAME} poweroff

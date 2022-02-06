#!/bin/bash
DATE_START=`date +%s`
vagrant up
VAGRANT_END=`date +%s`
ansible-playbook ../common/register-rh.yml -i inventory -i inventory-mc -e @~/.rhsm --vault-password-file ~/.vaultpw
REGISTER_END=`date +%s`
ansible-playbook -i inventory rancher_manager_playbook/site.yml -e @values.yml
MANAGER_END=`date +%s`
# Read an API token from Rancher console
echo -n "Rancher Manager API token: "
read apitoken
READ_END=`date +%s`
ansible-playbook -i inventory-mc rancher_managed_playbook/site.yml -e @values-managed.yml
MANAGED_END=`date +%s`

echo Vagrant took: $(($VAGRANT_END - $DATE_START)) secs
echo Registering took: $(($REGISTER_END - $VAGRANT_END)) secs
echo Deploying manager took: $(($MANAGER_END - $REGISTER_END)) secs
echo Waiting for API key: $(($READ_END - $MANAGED_END)) secs
echo Deploying managed took: $(($MANAGED_END - $READ_END)) secs
echo Total time: $(($MANAGED_END - $DATE_START)) secs

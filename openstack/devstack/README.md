# DevStack PoC

## Prérequis
- Ubuntu (VM ou bare metal) avec accès sudo
- Paquets de base : `git`, `curl`, `python3`

## Déploiement
```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://opendev.org/openstack/devstack
cd devstack && sudo ./stack.sh
. openrc admin admin
openstack service list | tee ../../audit/demo_audit/proofs/openstack_services.txt
openstack endpoint list | tee ../../audit/demo_audit/proofs/openstack_endpoints.txt
```

## Nettoyage
```bash
./unstack.sh && ./clean.sh
```

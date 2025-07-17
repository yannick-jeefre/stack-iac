# Déploiement Automatisé avec Terraform & Ansible

## Objectif du projet

Ce projet a pour objectif d'automatiser le déploiement et la configuration d'une infrastructure virtuelle (VMs) via Terraform (dans un environnement Proxmox) et Ansible.

Le script `deploy.sh` permet de :
- Déployer l'infrastructure avec Terraform
- Générer dynamiquement l'inventaire Ansible
- Configurer les machines virtuelles avec Ansible
- Vérifier l'état final des VMs

Un script `destroy.sh` est fourni pour supprimer l'infrastructure proprement.

## Structure du projet

.
├── ansible/
│ └── playbook.yml # Playbook Ansible pour configurer les VMs
├── terraform/
│ ├── main.tf # Définition de l’infrastructure
│ └── ansible_inventory.yml # Inventaire Ansible généré automatiquement
├── deploy.sh # Script principal de déploiement
├── destroy.sh # Script de destruction
└── inventory.tpl # Template pour générer l'inventaire Ansible

markdown
Copier
Modifier

## Prérequis

Avant d'exécuter les scripts, assurez-vous que les outils suivants sont installés sur votre machine :

- Terraform
- Ansible
- Accès à un hôte Proxmox avec les identifiants API
- Clé SSH permettant l'accès root aux VMs déployées

## Lancer le déploiement

Exécuter simplement le script suivant :

```bash
./deploy.sh
Ce script réalise automatiquement les étapes suivantes :

Vérification des dépendances et de la structure

Initialisation et application du plan Terraform

Génération de l'inventaire Ansible

Test de connectivité SSH

Exécution du playbook Ansible (avec option de dry-run)

Vérification finale et affichage d'un résumé

Vérification manuelle
Tester la connectivité avec les VMs via Ansible :

bash
Copier
Modifier
ansible all -i terraform/ansible_inventory.yml -m ping
Détruire l’environnement
Pour supprimer toutes les ressources :

bash
Copier
Modifier
./destroy.sh
Ce script :

Vérifie l'état actuel

Affiche les ressources existantes

Confirme avec l'utilisateur

Détruit les ressources Terraform

Sécurité
Ne versionnez jamais vos fichiers contenant des mots de passe ou des clés privées.

Utilisez des variables d’environnement ou des fichiers .tfvars sécurisés pour toute donnée sensible.

Liens utiles
Documentation Terraform

Documentation Ansible

API Proxmox

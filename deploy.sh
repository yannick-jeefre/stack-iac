#!/bin/bash

# Script de déploiement complet - Infrastructure + Configuration

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform"
ANSIBLE_DIR="ansible"
INVENTORY_FILE="$TERRAFORM_DIR/ansible_inventory.yml"
PLAYBOOK_FILE="$ANSIBLE_DIR/playbook.yml"

# Fonctions utilitaires
print_header() {
    echo -e "\n${BLUE}================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================================${NC}\n"
}

print_step() {
    echo -e "${CYAN}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Vérification des prérequis
check_prerequisites() {
    print_header "VÉRIFICATION DES PRÉREQUIS"
    
    # Vérifier la structure des répertoires
    if [ ! -d "$TERRAFORM_DIR" ]; then
        print_error "Répertoire $TERRAFORM_DIR introuvable"
        exit 1
    fi
    
    if [ ! -d "$ANSIBLE_DIR" ]; then
        print_error "Répertoire $ANSIBLE_DIR introuvable"
        exit 1
    fi
    
    # Vérifier les fichiers essentiels
    if [ ! -f "$TERRAFORM_DIR/main.tf" ]; then
        print_error "Fichier $TERRAFORM_DIR/main.tf introuvable"
        exit 1
    fi
    
    if [ ! -f "$PLAYBOOK_FILE" ]; then
        print_error "Fichier $PLAYBOOK_FILE introuvable"
        exit 1
    fi
    
    # Vérifier les outils
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform n'est pas installé"
        exit 1
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "Ansible n'est pas installé"
        exit 1
    fi
    
    print_success "Tous les prérequis sont satisfaits"
}

# Déploiement Terraform
deploy_infrastructure() {
    print_header "DÉPLOIEMENT DE L'INFRASTRUCTURE TERRAFORM"
    
    cd "$TERRAFORM_DIR"
    
    print_step "Initialisation de Terraform..."
    terraform init
    
    print_step "Planification du déploiement..."
    terraform plan
    
    print_warning "Le déploiement va créer des ressources dans Proxmox"
    read -p "Continuer le déploiement ? (y/N) : " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_warning "Déploiement annulé"
        exit 0
    fi
    
    print_step "Déploiement en cours..."
    terraform apply -auto-approve
    
    if [ $? -eq 0 ]; then
        print_success "Infrastructure déployée avec succès"
    else
        print_error "Échec du déploiement Terraform"
        exit 1
    fi
    
    cd - > /dev/null
}

# Vérification de l'inventaire
verify_inventory() {
    print_header "VÉRIFICATION DE L'INVENTAIRE ANSIBLE"
    
    if [ ! -f "$INVENTORY_FILE" ]; then
        print_error "Fichier d'inventaire $INVENTORY_FILE introuvable"
        exit 1
    fi
    
    print_step "Contenu de l'inventaire :"
    cat "$INVENTORY_FILE"
    
    print_step "Test de connectivité SSH..."
    if ansible all -i "$INVENTORY_FILE" -m ping -o; then
        print_success "Toutes les VMs sont accessibles"
    else
        print_error "Problème de connectivité avec certaines VMs"
        print_warning "Vérifiez que les VMs sont démarrées et que SSH est configuré"
        exit 1
    fi
}

# Configuration Ansible
configure_vms() {
    print_header "CONFIGURATION DES VMS AVEC ANSIBLE"
    
    print_step "Affichage des informations des VMs..."
    ansible all -i "$INVENTORY_FILE" -m setup -a "filter=ansible_hostname,ansible_default_ipv4" | grep -E "(vm-[0-9]+|address)"
    
    print_step "Exécution du playbook de configuration..."
    
    # Option pour mode dry-run
    read -p "Voulez-vous d'abord exécuter en mode test (dry-run) ? (y/N) : " dry_run
    
    if [[ $dry_run =~ ^[Yy]$ ]]; then
        print_step "Exécution en mode test..."
        ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE" --check
        
        read -p "Procéder à la configuration réelle ? (y/N) : " proceed
        if [[ ! $proceed =~ ^[Yy]$ ]]; then
            print_warning "Configuration annulée"
            exit 0
        fi
    fi
    
    print_step "Configuration en cours..."
    ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Configuration Ansible terminée avec succès"
    else
        print_error "Échec de la configuration Ansible"
        exit 1
    fi
}

# Vérification finale
final_verification() {
    print_header "VÉRIFICATION FINALE"
    
    print_step "État des VMs après configuration :"
    ansible all -i "$INVENTORY_FILE" -a "uptime" -o
    
    print_step "Hostnames configurés :"
    ansible all -i "$INVENTORY_FILE" -a "hostname" -o
    
    print_step "Espace disque :"
    ansible all -i "$INVENTORY_FILE" -a "df -h /" -o
    
    print_success "Déploiement terminé avec succès !"
}

# Affichage du résumé
show_summary() {
    print_header "RÉSUMÉ DU DÉPLOIEMENT"
    
    cd "$TERRAFORM_DIR"
    
    echo -e "${CYAN}📋 Informations des VMs créées :${NC}"
    terraform output
    
    echo -e "\n${CYAN}🔧 Commandes utiles :${NC}"
    echo "• Afficher l'état Terraform : cd $TERRAFORM_DIR && terraform show"
    echo "• Tester Ansible : ansible all -i $INVENTORY_FILE -m ping"
    echo "• Exécuter un playbook : ansible-playbook -i $INVENTORY_FILE $PLAYBOOK_FILE"
    echo "• Détruire l'environnement : ./destroy.sh"
    
    cd - > /dev/null
}

# Fonction principale
main() {
    print_header "DÉPLOIEMENT AUTOMATISÉ - TERRAFORM + ANSIBLE"
    
    echo -e "${YELLOW}Ce script va :${NC}"
    echo "1. Vérifier les prérequis"
    echo "2. Déployer l'infrastructure avec Terraform"
    echo "3. Configurer les VMs avec Ansible"
    echo "4. Effectuer une vérification finale"
    echo
    
    read -p "Commencer le déploiement ? (y/N) : " start
    
    if [[ ! $start =~ ^[Yy]$ ]]; then
        print_warning "Déploiement annulé"
        exit 0
    fi
    
    # Horodatage du début
    START_TIME=$(date +%s)
    
    # Exécution des étapes
    check_prerequisites
    deploy_infrastructure
    verify_inventory
    configure_vms
    final_verification
    show_summary
    
    # Temps d'exécution
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    print_header "DÉPLOIEMENT TERMINÉ"
    print_success "Temps d'exécution : ${DURATION}s"
    print_success "Votre environnement est prêt à être utilisé !"
}

# Gestion des erreurs
trap 'print_error "Une erreur est survenue. Déploiement interrompu."; exit 1' ERR

# Exécution
main "$@"

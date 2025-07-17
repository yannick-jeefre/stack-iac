#!/bin/bash

# Script de destruction de l'environnement

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

# Vérification de l'existence de l'environnement
check_environment() {
    print_header "VÉRIFICATION DE L'ENVIRONNEMENT"
    
    if [ ! -d "$TERRAFORM_DIR" ]; then
        print_error "Répertoire $TERRAFORM_DIR introuvable"
        exit 1
    fi
    
    if [ ! -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
        print_warning "Aucun état Terraform trouvé"
        print_warning "L'environnement semble déjà détruit ou n'a jamais été créé"
        exit 0
    fi
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform n'est pas installé"
        exit 1
    fi
    
    print_success "Environnement détecté"
}

# Affichage de l'état actuel
show_current_state() {
    print_header "ÉTAT ACTUEL DE L'ENVIRONNEMENT"
    
    cd "$TERRAFORM_DIR"
    
    print_step "Ressources Terraform actuelles :"
    terraform show -no-color | head -50
    
    if [ -f "$INVENTORY_FILE" ]; then
        print_step "VMs dans l'inventaire Ansible :"
        cat "$INVENTORY_FILE"
        
        print_step "Test de connectivité (optionnel) :"
        if command -v ansible &> /dev/null; then
            ansible all -i "$INVENTORY_FILE" -m ping -o 2>/dev/null || print_warning "Certaines VMs sont inaccessibles"
        else
            print_warning "Ansible non installé, impossible de tester la connectivité"
        fi
    fi
    
    cd - > /dev/null
}

# Destruction Terraform
destroy_infrastructure() {
    print_header "DESTRUCTION DE L'INFRASTRUCTURE"
    
    cd "$TERRAFORM_DIR"
    
    print_step "Planification de la destruction..."
    terraform plan -destroy
    
    echo -e "\n${RED}⚠️  ATTENTION ⚠️${NC}"
    echo -e "${RED}Cette action va DÉTRUIRE DÉFINITIVEMENT :${NC}"
    echo "• Toutes les VMs créées"
    echo "• Tous les disques associés"
    echo "• Toute la configuration réseau"
    echo "• Toutes les données non sauvegardées"
    echo
    
    read -p "Êtes-vous ABSOLUMENT sûr de vouloir continuer ? (tapez 'y' pour confirmer) : " confirm
    
    if [ "$confirm" != "y" ]; then
        print_warning "Destruction annulée"
        exit 0
    fi
    
    print_step "Destruction en cours..."
    terraform destroy -auto-approve
    
    if [ $? -eq 0 ]; then
        print_success "Infrastructure détruite avec succès"
    else
        print_error "Échec de la destruction Terraform"
        print_warning "Vérifiez manuellement l'état des ressources dans Proxmox"
        exit 1
    fi
    
    cd - > /dev/null
}

# Fonction principale
main() {
    print_header "DESTRUCTION DE L'ENVIRONNEMENT TERRAFORM + ANSIBLE"
    
    echo -e "${YELLOW}Ce script va :${NC}"
    echo "1. Vérifier l'environnement existant"
    echo "2. Afficher l'état actuel"
    echo "3. Créer une sauvegarde"
    echo "4. Nettoyer les VMs (optionnel)"
    echo "5. Détruire l'infrastructure Terraform"
    echo "6. Nettoyer les fichiers locaux (optionnel)"
    echo
    
    read -p "Commencer la destruction ? (y/N) : " start
    
    if [[ ! $start =~ ^[Yy]$ ]]; then
        print_warning "Destruction annulée"
        exit 0
    fi
    
    # Horodatage du début
    START_TIME=$(date +%s)
    
    # Exécution des étapes
    check_environment
    show_current_state
    destroy_infrastructure
    
    # Temps d'exécution
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    print_header "DESTRUCTION TERMINÉE"
    print_success "Temps d'exécution : ${DURATION}s"
    print_success "Environnement détruit avec succès !"
    
    echo -e "\n${CYAN}📋 Pour redéployer :${NC}"
    echo "• Exécutez : ./deploy.sh"
    echo "• Ou manuellement : cd terraform && terraform apply"
}

# Gestion des erreurs
trap 'print_error "Une erreur est survenue. Destruction interrompue."; exit 1' ERR

# Exécution
main "$@"

.PHONY: help deploy destroy ping inventory configure clean

help:
	@echo "Commandes disponibles :"
	@echo "  make deploy      -> Lance le déploiement complet (Terraform + Ansible)"
	@echo "  make destroy     -> Détruit l'infrastructure"
	@echo "  make ping        -> Teste la connectivité Ansible"
	@echo "  make inventory   -> Affiche l'inventaire Ansible"
	@echo "  make configure   -> Exécute uniquement le playbook Ansible"
	@echo "  make clean       -> Supprime les fichiers Terraform générés"

deploy:
	@echo "Déploiement de l'environnement..."
	./deploy.sh

destroy:
	@echo "Destruction de l'environnement..."
	./destroy.sh

ping:
	ansible all -i terraform/ansible_inventory.yml -m ping

inventory:
	@echo "Inventaire Ansible généré :"
	@cat terraform/ansible_inventory.yml

configure:
	ansible-playbook -i terraform/ansible_inventory.yml ansible/playbook.yml

clean:
	rm -rf terraform/.terraform terraform/*.tfstate terraform/*.tfstate.backup terraform/ansible_inventory.yml terraform/.terraform.lock.hcl

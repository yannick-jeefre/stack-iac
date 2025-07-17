variable "proxmox_api_url" {
  description = "Url du serveur Proxmox"
  type        = string
}

variable "proxmox_user" {
  description = "Compte root du serveur Proxmox"
  type	      = string
}

variable "proxmox_password" {
  description = "Mot de passe du compte root du serveur Proxmox"
  type        = string
  sensitive   = true
}

variable "node_name" {
  description = "Nom du noeud du serveur Proxmox"
  type        = string
}

variable "vm_count" {
  description = "Nombre de VM par défaut à créer"
  default     = 4
  type        = number
}

variable "template_username" {
  description = "Username par défaut du template"
  type        = string
  sensitive   = true
}

variable "template_password" {
  description = "Password par défaut du template"
  type        = string
  sensitive   = true
}

# Section des variables
# Cette section définit les variables utilisées dans toute la configuration Terraform
variable "subscription_id" {
  description = "ID de l'abonnement Azure"
  default     = "765266c6-9a23-4638-af32-dd1e32613047"
}

variable "resource_group_name" {
  description = "Nom du groupe de ressources Azure"
  default     = "ADDA84-CTP"
}

variable "location" {
  description = "Région Azure"
  default     = "francecentral"
}

variable "subnet_name" {
  description = "Nom du sous-réseau existant"
  default     = "internal"
}

variable "virtual_network_name" {
  description = "Nom du réseau virtuel existant"
  default     = "network-tp4"
}

variable "student_id" {
  description = "Identifiant de l'étudiant"
  type        = string
  default     = "20230369"
}

# Section des locals
# Définition de la valeur locale custom_data, à utiliser ultérieurement pour injecter des données Cloud-init dans les machines virtuelles
locals {
  custom_data = <<-EOF
                #cloud-config
                package_update: true
                package_upgrade: true
                packages:
                  - docker.io
                EOF
}

# Bloc Terraform définissant les fournisseurs requis
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Bloc de données pour le sous-réseau Azure qui récupère des informations sur un sous-réseau existant
data "azurerm_subnet" "subnet1" {
  name                 = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

# Bloc de fournisseur pour configurer le fournisseur Azure avec les détails d'abonnement
provider "azurerm" {
  features {}
  subscription_id            = var.subscription_id
  skip_provider_registration = true
}

# Génération d'une clé privée SSH RSA avec une taille de 4096 bits
resource "tls_private_key" "ssh_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Bloc de ressource pour définir une ressource IP publique Azure
resource "azurerm_public_ip" "public_ip" {
  name                = "devops-${var.student_id}-publicip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Bloc de ressource qui définit un NSG Azure avec des règles de sécurité
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.student_id}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Règles de sécurité autorisant le trafic SSH, HTTP et HTTPS
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Bloc de ressource pour définir une interface réseau Azure
resource "azurerm_network_interface" "network_interface" {
  name                = "nic-${var.student_id}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Configuration IP pour l'interface réseau
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Bloc de ressource pour définir une machine virtuelle Linux Azure
resource "azurerm_linux_virtual_machine" "main" {
  name                = "devops-${var.student_id}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = "devops"
  computer_name       = "devops-${var.student_id}"
  # Spécifie les données personnalisées à fournir à la machine. 
  # Sur les systèmes basés sur Linux, cela peut être utilisé comme un script cloud-init. Sur d'autres systèmes, cela sera copié en tant que fichier sur le disque.
  custom_data = base64encode(local.custom_data)

  # ID des interfaces réseau attachées à la machine virtuelle
  network_interface_ids = [
    azurerm_network_interface.network_interface.id,
  ]

  # Clé SSH pour accéder à la machine virtuelle
  admin_ssh_key {
    username   = "devops"
    public_key = tls_private_key.ssh_private_key.public_key_openssh
  }

  # Configuration du disque OS
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Référence de l'image source pour la machine virtuelle
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Bloc de ressource pour associer un NSG à une interface réseau
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.network_interface.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Bloc de ressource pour exécuter une commande locale afin de générer et enregistrer une clé SSH
resource "null_resource" "generate_and_save_ssh_key" {
  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.ssh_private_key.public_key_openssh}' > ~/.ssh/id_rsa.pub
      chmod 644 ~/.ssh/id_rsa.pub
    EOT
  }
}

# Bloc de sortie pour exposer le contenu de la clé privée
output "private_key_content" {
  value     = tls_private_key.ssh_private_key.private_key_pem
  sensitive = true
}

# Bloc de sortie pour exposer l'adresse IP publique
output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}
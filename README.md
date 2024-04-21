# Devops - 20230369
## TP1

Ce projet (#20230369) a pour objectif de simplifier l'accès aux données météorologiques d'un lieu spécifique via l'API OpenWeather en développant un wrapper. Ce dernier est encapsulé dans une image Docker, offrant ainsi une distribution aisée et une utilisation optimale.

### Contenu du Projet

- **weather-wrapper.py**: Un script Python qui utilise les coordonnées géographiques (latitude et longitude) et une clé d'API OpenWeather comme variables d'environnement pour récupérer les données météorologiques.

- **Dockerfile**: Ce fichier décrit les étapes pour construire l'image Docker contenant le wrapper.

### Étapes du Projet

1. **Création d'un compte sur OpenWeather et obtention d'une clé d'API**: Une clé d'API OpenWeather est requise pour accéder aux données météorologiques.

2. **Développement du wrapper en Python**: Python a été choisi pour sa popularité et sa facilité d'utilisation.

3. **Construction de l'image Docker**:
   - Sélection de l'image Python sans vulnérabilités : `cgr.dev/chainguard/python:latest-dev`.
   - Création du Dockerfile pour définir les étapes de construction de l'image Docker.
   - Création de l'image Docker avec la commande :
     ```
     docker build -t maregistry/api:1.0.0 .
     ```
   - Vérification des vulnérabilités de l'image avec Trivy :
     ```
     trivy image maregistry/api:1.0.0
     ```

4. **Publication sur DockerHub**:
   - Tagging de l'image Docker :
     ```
     docker tag maregistry/api:1.0.0 aymenzem/api:1.0.0
     ```
   - Publication de l'image Docker sur DockerHub :
     ```
     docker push aymenzem/api:1.0.0
     ```

## Utilisation

1. **Clonage du Repository**:
```
git clone <URL_du_repository>
```

2. **Construction de l'Image Docker**:
```
docker build -t nom_image .
```

3. **Exécution de l'Image Docker**:
```
docker run --env LAT=<latitude> --env LONG=<longitude> --env API_KEY=<api_key> nom_image
```

### Sécurité et Qualité

- **Vérification des vulnérabilités de l'image Docker**:
L'analyse avec Trivy a révélé qu'il n'y a aucune CVE (Common Vulnerabilities and Exposures) dans l'image Docker `maregistry/api:1.0.0`. Pour exécuter l'analyse avec Trivy, utilisez la commande suivante :
```
trivy image maregistry/api:1.0.0
```
- **Vérification de la qualité du Dockerfile**:
Aucune erreur de lint n'a été détectée dans le Dockerfile, attestant ainsi de sa qualité. Pour exécuter Hadolint et vérifier le Dockerfile, assurez-vous d'être dans le répertoire du projet, puis exécutez :
```
docker run --rm -i hadolint/hadolint < Dockerfile
```

- **Protection des données sensibles**:
Aucune donnée sensible, telle que la clé d'API OpenWeather, n'est stockée dans l'image Docker pour garantir la sécurité des informations.

### URLs Publiques

- **Repository GitHub**: [URL_repository_GitHub](https://github.com/efrei-ADDA84/20230369.git)
- **Registre DockerHub**: [URL_registry_DockerHub](https://hub.docker.com/repository/docker/aymenzem/api/general)

## TP2

### Transformation du wrapper en API
Refonte du code: Le code du wrapper a été modifié pour créer une API RESTful à l'aide de Flask. Voici un exemple de code pour un endpoint de l'API :

```python
from flask import Flask, request, jsonify
import os
import requests
from waitress import serve

app = Flask(__name__)

@app.route('/')
def get_weather():
    latitude = request.args.get('lat')
    longitude = request.args.get('lon')
    
    api_key = os.getenv("API_KEY")
    if not api_key:
        return jsonify({"error": "API_KEY environment variable not set"}), 500

    url = f"http://api.openweathermap.org/data/2.5/weather?lat={latitude}&lon={longitude}&appid={api_key}&units=metric"
    response = requests.get(url)
    data = response.json()
    
    if response.status_code == 200:
        formatted_weather = format_weather_data(data)
        return jsonify({"weather": formatted_weather})
    else:
        return jsonify({"error": data["message"]}), response.status_code

def format_weather_data(weather_data):
    #function to format the weather data
    pass

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)
```

Utilisation du serveur WSGI Waitress pour le déploiement, car plus robuste et plus adapté pour les besoins en production :

```python
# Imports ...
from waitress import serve

# Same code ...

if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=8081)
```

### Modification du Dockerfile et requirements.txt
- Ajout de la commande au Dockerfile : 
```
EXPOSE 8081
````
Exposer le port 8081 utilisé par notre application, permettant ainsi à d'autres services de communiquer avec elle.
- Ajout de *flask* et *waitress* a requirements.txt
```
requests
flask
waitress
```
### Configuration du workflow Github Action 
Un workflow GitHub Action a été configuré pour automatiser la construction et le déploiement de l'image Docker, en plus de vérifier l'absence d'erreurs avec Hadolint.

Remarque : Le warning DL3007 a été ignoré car la plateforme Chainguard, qui fournit des images Python sans vulnérabilités, fournit directement la dernière version en utilisant l'attribut "latest". Pour une version spécifique, une demande doit être faite.

```yaml
name: Build and Push Docker Image

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2
      
      - name: Install Hadolint
        run: |
          wget -O hadolint https://github.com/hadolint/hadolint/releases/download/v2.7.0/hadolint-Linux-x86_64
          chmod +x hadolint
          sudo mv hadolint /usr/local/bin/hadolint
      
      - name: Lint Dockerfile
        # Ignoring DL3007 because I cannot access a specific version of the chainguard package; only the latest version is available.
        run: hadolint --ignore DL3007 tp2/Dockerfile 

      - name: Login to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Declare some variables
        shell: bash
        run: |
          calculatedSha=$(git rev-parse --short "${{ github.sha }}")
          echo "COMMIT_SHORT_SHA=$calculatedSha" >> $GITHUB_ENV
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v2
        with:
          context: ./tp2
          file: ./tp2/Dockerfile
          push: true
          tags: aymenzem/efrei-devops-tp2:${{ env.COMMIT_SHORT_SHA }}
```

- Pour garantir la sécurité des informations sensibles telles que les identifiants et les mots de passe, GitHub permet de stocker ces données dans des secrets. Dans notre workflow GitHub Action, nous utilisons les secrets pour stocker les informations d'identification de Docker Hub, nécessaires pour se connecter et pousser l'image Docker.

- Création de l'image Docker avec le tag correspondant au hachage du commit.


### Exécution 

- Télécharger l'image depuis Docker Hub :

```
docker pull aymenzem/efrei-devops-tp2:1.0.0
```

- Lancez la commande pour démarrer le conteneur hébergeant l'API.

```
docker run -d --network host --env API_KEY=<API_KEY> aymenzem/efrei-devops-tp2:1.0.0
```

- Ouvrir un autre terminal sur la machine, puis exécuter la commande suivante pour obtenir les données météorologiques :
```
curl "http://localhost:8081/?lat=5.902785&lon=102.754175"
```

## TP3 
Dans le cadre de ce TP, notre objectif est de déployer une API dockerisée sur Azure Container Instance (ACI) en utilisant GitHub Actions pour automatiser le processus. Pour ce faire, nous avons créé un nouveau dossier nommé tp3, contenant un code légèrement modifié. Nous avons également opté pour une autre image Python (`python:3.12-alpine`) que celle utilisée dans les TP précédents, car l'image de `chainguard` a rencontré quelques problèmes lors du déploiement sur ACI.

Nous avons ensuite modifié le fichier workflow en y ajoutant les étapes nécessaires pour la construction de l'image Docker, son déploiement sur Azure Container Registry (ACR), et enfin son déploiement sur Azure Container Instance (ACI). Ces modifications sont expliquées dans ce qui suit.


### Construction et Publication de l'Image Docker :
Nous avons utilisé l'action GitHub `docker/build-push-action` pour construire l'image Docker à partir du Dockerfile fourni et la publier dans le registre Docker Hub. Cette action garantit que l'image Docker est construite et versionnée de manière cohérente.

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v2
  with:
    # Spécifie le répertoire contenant les fichiers nécessaires à la construction de l'image Docker.
    context: ./tp3
    # Chemin vers le Dockerfile utilisé pour construire l'image.
    file: ./tp3/Dockerfile
    # Indique que l'image doit être publiée après sa construction.
    push: true
    # Tags de l'image Docker, généralement basés sur des informations comme le SHA de validation du commit.
    tags: aymenzem/efrei-devops-tp3:${{ env.COMMIT_SHORT_SHA }}
```

### Connexion au Registre de Conteneurs Azure :
Nous avons utilisé l'action GitHub `azure/docker-login` pour nous authentifier auprès du Registre de Conteneurs Azure. Cette action se connecte de manière sécurisée au registre ACR en utilisant les identifiants fournis et stockés en tant que secrets GitHub.

```yaml
- name: Login to Azure Container Registry
  uses: azure/docker-login@v1
  with:
    # L'URL du registre de conteneurs Azure.
    login-server: ${{ secrets.REGISTRY_LOGIN_SERVER }}
    # Le nom d'utilisateur pour l'authentification.
    username: ${{ secrets.REGISTRY_USERNAME }}
    # Le mot de passe pour l'authentification.
    password: ${{ secrets.REGISTRY_PASSWORD }}
```

### Étiquetage et Publication de l'Image Docker dans l'ACR :
L'image Docker est étiquetée avec le nom du référentiel ACR et publiée dans l'ACR à l'aide de commandes Docker standard. Cette étape garantit que l'image Docker est disponible dans l'environnement cloud Azure.

```yaml
- name: Tag Docker image for Azure Container Registry
  # Étiquetage de l'image Docker avec le nom du référentiel ACR.
  run: docker tag aymenzem/efrei-devops-tp3:${{ env.COMMIT_SHORT_SHA }} ${{ secrets.REGISTRY_LOGIN_SERVER }}/${{ secrets.AC_NAME }}:v1
        
- name: Push Docker image to Azure Container Registry
  # Publication de l'image Docker dans l'ACR.
  run: docker push ${{ secrets.REGISTRY_LOGIN_SERVER }}/${{ secrets.AC_NAME }}:v1
```

### Connexion à Azure :
Nous nous sommes connectés à l'environnement Azure en utilisant l'action GitHub `azure/login`, qui s'authentifie auprès d'Azure en utilisant les informations d'identification du principal de service fournies et stockées en tant que secrets GitHub.

```yaml
- name: Login to Azure
  uses: azure/login@v1
  with:
    # Les informations d'identification du principal de service utilisé pour s'authentifier auprès de l'environnement Azure.
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

### Déploiement dans l'Instance de Conteneur Azure :
Enfin, nous avons déployé l'image Docker dans l'Instance de Conteneur Azure en utilisant l'action GitHub `azure/aci-deploy`. Cette action provisionne une instance ACI avec l'image Docker provenant de l'ACR, configure le réseau et expose le point de terminaison de l'API.

```yaml
- name: Deploy to Azure Container Instance
  uses: azure/aci-deploy@v1
  with:
    # Spécifie le nom du groupe de ressources Azure dans lequel l'instance de conteneur sera déployée.
    resource-group: ${{ secrets.RESOURCE_GROUP }}
    # Définit le nom de l'instance de conteneur à déployer.
    name: ${{ secrets.AC_NAME }}
    # Spécifie l'URL de l'image Docker à déployer.
    image: ${{ secrets.REGISTRY_LOGIN_SERVER }}/${{ secrets.AC_NAME }}:v1
    # Indique la région Azure dans laquelle déployer l'instance de conteneur.
    location: germanywestcentral
    # Ce libellé DNS est utilisé pour l'instance de conteneur afin d'exposer l'API via Internet.
    dns-name-label: devops-${{ secrets.AC_NAME }}
    # Fournit les informations d'identification nécessaires pour accéder au registre Azure Container Registry (ACR).
    registry-username: ${{ secrets.REGISTRY_USERNAME }}
    registry-password: ${{ secrets.REGISTRY_PASSWORD }}
    # Définit des variables d'environnement sécurisées qui seront injectées dans l'instance de conteneur.
    secure-environment-variables: API_KEY=${{ secrets.API_KEY }}
```

## TP4 
Dans ce TP4, nous allons explorer l'utilisation de Terraform pour la gestion des ressources sur Azure. Ce TP sera divisé en deux parties : la partie code, où nous définirons l'infrastructure à l'aide de fichiers Terraform, et la partie exécution, où nous mettrons en œuvre les étapes nécessaires pour déployer et gérer ces ressources sur le cloud Azure.

### Code Tarraform
#### Partie Déclaration de Variables:
Dans cette première partie, nous avons défini les variables nécessaires pour notre configuration Terraform. Cela inclut des informations telles que l'ID d'abonnement Azure, le nom du groupe de ressources, la région, etc. Ces variables permettent une personnalisation facile de notre configuration et simplifient la gestion des valeurs réutilisables dans tout le code.

```terraform
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
```

#### Provider Azure:
Nous avons configuré le fournisseur Azure dans Terraform pour nous connecter à notre compte Azure. Cela inclut la spécification de l'ID d'abonnement et l'activation des fonctionnalités requises. Cette étape est cruciale car elle établit la connexion entre notre configuration Terraform et notre environnement Azure cible.

```terraform
# Bloc Terraform définissant les fournisseurs requis
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Bloc de fournisseur pour configurer le fournisseur Azure avec les détails d'abonnement
provider "azurerm" {
  features {}
  subscription_id            = var.subscription_id  
  skip_provider_registration = true
}
```
#### Déclaration des Ressources:
Nous avons déclaré différentes ressources Azure telles que les IP publiques, les machines virtuelles, les groupes de sécurité réseau (NSG), etc. Ces déclarations définissent les propriétés de chaque ressource, telles que le nom, la région, le type, etc. Utiliser Terraform pour déclarer des ressources nous permet d'adopter une approche infrastructure-as-code, où notre infrastructure est décrite de manière reproductible et versionnée.

```terraform
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
  custom_data         = base64encode(local.custom_data)

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
```

#### Association NSG:
Nous avons associé les groupes de sécurité réseau (NSG) aux interfaces réseau pour contrôler le trafic entrant et sortant des machines virtuelles. Cette étape est essentielle pour garantir la sécurité de notre infrastructure en limitant l'accès aux ports et protocoles nécessaires.

```terraform
# Bloc de ressource pour associer un NSG à une interface réseau
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.network_interface.id  
  network_security_group_id = azurerm_network_security_group.nsg.id  
}
```

#### Génération de Clés SSH:
Nous avons inclus une étape pour générer et enregistrer une paire de clés SSH (publique et privée) pour chaque machine virtuelle. Cela nous permet d'accéder de manière sécurisée à la machine virtuelle via SSH. Terraform nous permet d'exécuter des scripts locaux pour automatiser cette tâche, garantissant ainsi une configuration cohérente des clés SSH pour chaque déploiement. 

```terraform
resource "tls_private_key" "ssh_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
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
```

La clé privée générée sera ensuite sortie (output) de manière sécurisée à l'aide de Terraform. Cela signifie que Terraform fournira la clé privée sous forme de sortie à la fin du déploiement, mais cette sortie sera marquée comme sensible (sensitive), ce qui garantit que la clé privée ne sera pas affichée dans les journaux ou dans d'autres sorties non sécurisées de Terraform

```terraform
# Bloc de sortie pour exposer le contenu de la clé privée
output "private_key_content" {
  value     = tls_private_key.ssh_private_key.private_key_pem  
  sensitive = true  
}
```

#### Exécution d'un script au démarrage pour installer Docker via cloud-init
Cette étape de code Terraform définit une valeur locale nommée custom_data, qui contient un script Cloud-init pour installer Docker lors du démarrage des machines virtuelles Azure. Ce script est ensuite encodé en base64 et injecté dans la configuration de la machine virtuelle.

```terraform
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

# Bloc de ressource pour définir une machine virtuelle Linux Azure
resource "azurerm_linux_virtual_machine" "main" {

  ...
  
  # Spécifie les données personnalisées à fournir à la machine. 
  # Sur les systèmes basés sur Linux, cela peut être utilisé comme un script cloud-init. Sur d'autres systèmes, cela sera copié en tant que fichier sur le disque.
  custom_data         = base64encode(local.custom_data)   
  
  ...
}
```


### Intérêt de l'utilisation de Terraform pour déployer des ressources sur le cloud
L'utilisation de Terraform pour déployer des ressources sur le cloud présente plusieurs avantages :
- **Déclaratif et Infrastructure as Code (IaC)** : Facilite la gestion, la réutilisation et la collaboration grâce à la définition déclarative de l'infrastructure.
- **Multicloud** : Prend en charge plusieurs fournisseurs de cloud pour déployer sur différentes plateformes avec un seul outil.
- **Gestion du cycle de vie** : Gère le cycle complet des ressources, de la création à la suppression, de manière cohérente.
- **Idempotence** : Les déploiements sont idempotents, évitant la création de doublons de ressources.
- **Planification et validation** : Permet de visualiser les changements avant de les appliquer, réduisant les risques d'erreurs.

Comparé à la CLI ou à l'interface utilisateur :
- La CLI et l'interface utilisateur sont adaptées pour des tâches ponctuelles, tandis que Terraform est mieux adapté pour la gestion automatisée à grande échelle.
- Terraform conserve un historique des modifications et offre une meilleure visibilité et un meilleur contrôle sur l'infrastructure, facilitant la collaboration et

### Exécution
Pour exécuter le code Terraform, vous devez suivre les étapes suivantes dans le répertoire où se trouve votre fichier Terraform (habituellement `main.tf`)

Avant d'exécuter les commandes, assurez-vous de formater votre code Terraform de manière cohérente en utilisant la commande suivante :

```bash
terraform fmt
```

#### Initialisation
Exécutez la commande suivante pour initialiser Terraform et télécharger les plugins nécessaires :

```bash
terraform init
```

#### Planification
Exécutez la commande suivante pour générer un plan d'exécution. Cette étape vous permet de voir quels changements Terraform va apporter à votre infrastructure avant de les appliquer :
```bash
terraform plan -out=tfplan
```

#### Application
Si le plan vous convient, appliquez les changements en exécutant la commande suivante. Terraform demandera confirmation avant d'appliquer les modifications :

```bash
terraform apply "tfplan"
```

L'adresse ip publique de la machine devrait s'afficher dans les logs. Assurez-vous de la noter, car vous en aurez besoin pour vous connecter à la machine virtuelle.

#### Récupération de la clé privé SSH
La clé privé est une information sensible qui ne s'affiche pas directement dans les logs, on doit la récuperer et la mettre dans le fichier "id_rsa", en utilisant la commande :

```bash
terraform output -raw private_key_content > id_rsa
```

Ensuite, pour renforcer la sécurité de ce fichier, exécutez la commande :
```bash
chmod 600 id_rsa
```

#### Connexion à la machine en SSH
Après avoir récupéré la clé privée, vous pouvez vous connecter à la machine virtuelle en utilisant SSH avec la commande suivante :

```bash
ssh -i id_rsa devops@<ADRESSE_IP_PUBLIQUE>
```
Remplacez <ADRESSE_IP_PUBLIQUE> par l'adresse IP publique de la machine virtuelle que vous avez notée précédemment.

#### Destruction
Si vous souhaitez supprimer les ressources créées par Terraform, vous pouvez exécuter la commande suivante :

```bash
terraform destroy
```
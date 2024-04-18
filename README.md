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

```
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

# Rapport Projet Météo

Ce projet (#20230369) a pour objectif de simplifier l'accès aux données météorologiques d'un lieu spécifique via l'API OpenWeather en développant un wrapper. Ce dernier est encapsulé dans une image Docker, offrant ainsi une distribution aisée et une utilisation optimale.

## Contenu du Projet

- **weather-wrapper.py**: Un script Python qui utilise les coordonnées géographiques (latitude et longitude) et une clé d'API OpenWeather comme variables d'environnement pour récupérer les données météorologiques.

- **Dockerfile**: Ce fichier décrit les étapes pour construire l'image Docker contenant le wrapper.

## Étapes du Projet

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

## Sécurité et Qualité

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

## URLs Publiques

- **Repository GitHub**: [URL_repository_GitHub](https://github.com/efrei-ADDA84/20230369.git)
- **Registre DockerHub**: [URL_registry_DockerHub](https://hub.docker.com/repository/docker/aymenzem/api/general)

# Idées d'améliorations

Pistes pour la suite de Bric-à-Brac, groupées par thème et sans engagement. Dans chaque
section, les idées les plus utiles ou les moins coûteuses viennent en premier.

## Priorité : à valider en jouant

Le jeu n'a pour l'instant été vérifié que par des tests automatiques.

- Faire essayer les 18 niveaux à de vrais joueurs et noter où ils bloquent.
- Revoir la difficulté de la Catapulte et du Pendule, dont les zones gagnantes sont étroites.
- Écouter les sons en situation, surtout le volume des chocs répétés.

## Confort de jeu

- Bouton d'accélération de la simulation (x2, x4) et mode pause.
- Écran de sélection des niveaux avec vignettes, à la place de la liste déroulante.
- Trajectoire fantôme du dernier essai, pour ajuster une pose sans tout revoir.
- Prise en charge du tactile, pour une future version mobile.

## Nouvelles pièces

- Ventouse, élastique et chariot sur rail.
- Pièces animées : souris dans une roue, chat qui saute sur ce qui bouge.

## Contenu et rejouabilité

- Personnages ou animaux aux réactions simples, pour donner de l'humour aux machines.

## Éditeur et communauté

- Éditeur de niveaux en jeu, avec décor, inventaire et objectif.
- Vérification à la publication : un niveau partagé doit avoir été résolu par son auteur.
- Partage des niveaux et des solutions par fichier ou par code à copier.
- Relecture d'une solution, enregistrable en GIF ou en vidéo.

## Présentation

- Particules : éclats du ballon, fumée du canon, poussière des chocs.
- Écrasement et étirement des objets lors des impacts.
- Musique d'atelier discrète, avec un réglage de volume séparé des effets.
- Sons continus pour le tapis et le ventilateur.
- Écran titre et transitions entre les niveaux.
- Interface traduite, en commençant par l'anglais.
- Options d'accessibilité : couleurs de canaux adaptées, réduction des animations.

## Technique

- Rechercher l'origine de l'avertissement « ObjectDB instances leaked » des scripts de test.
- Rendre le vent bloquable par les obstacles : il traverse tout aujourd'hui.
- Faire s'enrouler la corde autour des poulies et la faire réagir aux obstacles.
- Réduire la variation de durée observée sur le niveau Dominos.
- Lancer les tests automatiquement sur GitHub Actions à chaque envoi.
- Déplacer les niveaux dans des fichiers de données, ce que l'éditeur demandera de toute façon.
- Mesurer les performances avec beaucoup d'objets : les corps physiques ne s'endorment jamais.

## Diffusion

- Préparer les exports Linux, Windows et web.
- Publier une démo jouable sur itch.io pour recueillir des retours.
- Illustrer le README avec des captures d'écran et un GIF.

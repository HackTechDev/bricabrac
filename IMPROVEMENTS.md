# Idées d'améliorations

Pistes pour la suite de Bric-à-Brac, groupées par thème et sans engagement. Dans chaque
section, les idées les plus utiles ou les moins coûteuses viennent en premier.

## Priorité : à valider en jouant

Le jeu n'a pour l'instant été vérifié que par des tests automatiques.

- Faire essayer les 36 niveaux à de vrais joueurs et noter où ils bloquent.
- Revoir la difficulté de la Catapulte et du Pendule, dont les zones gagnantes sont étroites.
- Régler en jouant le chat, l'élastique et la corde qui s'accroche aux obstacles, jusqu'ici
  réglés seulement par des tests.
- Vérifier que la nouvelle solution de la Bouée (ventilateur incliné) se trouve sans l'indice.
- Écouter les sons en situation, surtout le volume des chocs répétés.

## Nouveaux niveaux

- Des niveaux qui mettent en scène l'entonnoir, le tuyau coudé, l'aimant répulsif et la bougie,
  pour l'instant disponibles dans le bac à sable et l'éditeur.
- Un sixième monde, par exemple un grenier sombre où une lampe de poche éclaire le décor.
- Remplacer les niveaux « La fronde » et « Le hamster » de la galerie, qui ont maintenant leur
  version officielle, par d'autres niveaux d'exemple.

## Confort de jeu

- Sélection d'un groupe au cadre, en glissant sur une zone vide.
- Prise en charge du tactile, pour une future version mobile.

## Éditeur et communauté

- Mesurer la difficulté de la galerie à partir des essais de tous les joueurs, ce qui demande
  un serveur ; elle est aujourd'hui donnée par l'auteur ou déduite de sa solution.

## Contenu et rejouabilité

- D'autres animaux aux réactions simples : un chien qui court après la balle, un oiseau qui
  s'envole au bruit.
- Défis quotidiens : un niveau du jeu avec une contrainte en plus (sans tel type de pièce, en
  moins de x secondes).
- Pièces à venir : un tuyau droit de longueur réglable, une bougie que le vent souffle.

## Présentation

- D'autres particules : gouttes du bac d'eau, étincelles des engrenages.
- Une musique par monde, sur la même trame que celle de l'atelier.
- Montrer aussi l'ombre du souffle des ventilateurs.
- Faire relire la traduction anglaise par un anglophone, puis ajouter d'autres langues
  (un fichier `i18n/<code>.json` et une ligne dans `Lang.LANGUAGES`).
- Traduire aussi le tutoriel écrit (`TUTORIAL.md`) et le README.
- D'autres options d'accessibilité : taille du texte, commandes entièrement au clavier.

## Technique

- Chercher dans les autres niveaux des surfaces fixes qui se chevauchent à la même hauteur : un
  objet posé sur la jointure touche deux formes, dans un ordre qui change d'un essai à l'autre
  (c'était la cause de la variation de durée du niveau Dominos).
- Lancer les tests automatiquement sur GitHub Actions à chaque envoi.
- Mesurer les performances avec beaucoup d'objets : les corps physiques ne s'endorment jamais,
  et le vent comme la corde lancent maintenant des rayons à chaque pas de simulation.
- Vérifier les cartes de niveau et les vignettes par un test avec rendu, le mode sans écran ne
  produisant pas d'image.

## Diffusion

- Préparer les exports Linux, Windows et web, en vérifiant que l'export web charge bien les
  fichiers de `levels/`.
- Publier une démo jouable sur itch.io pour recueillir des retours.
- Illustrer le README avec des captures d'écran et un GIF, faits avec « Filmer en GIF ».

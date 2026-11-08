# Idées d'améliorations

Pistes pour la suite de Bric-à-Brac, groupées par thème et sans engagement. Dans chaque
section, les idées les plus utiles ou les moins coûteuses viennent en premier.

## Priorité : à valider en jouant

Le jeu n'a pour l'instant été vérifié que par des tests automatiques.

- Faire essayer les 18 niveaux à de vrais joueurs et noter où ils bloquent.
- Revoir la difficulté de la Catapulte et du Pendule, dont les zones gagnantes sont étroites.
- Régler en jouant le chat, l'élastique et la corde qui s'accroche aux obstacles, jusqu'ici
  réglés seulement par des tests.
- Vérifier que la nouvelle solution de la Bouée (ventilateur incliné) se trouve sans l'indice.
- Écouter les sons en situation, surtout le volume des chocs répétés.

## Nouveaux niveaux

Aucun niveau officiel n'utilise encore la ventouse, l'élastique, le chariot, la souris, le chat
ni les ciseaux. Chaque niveau ci-dessous en présente un, comme les premiers niveaux le font
pour les pièces de base.

- **La fronde** (atelier) : un élastique tendu à 50 % lance une bille par-dessus un mur vers
  un panier.
- **Prise ferme** (cuisine) : une ventouse retient une bille jusqu'à ce qu'une minuterie la
  lâche au bon moment, sur un tapis qui passe.
- **Le wagonnet** (usine) : un chariot sur rail transporte une caisse d'un quai à l'autre,
  poussé par un ventilateur.
- **Le hamster** (cuisine) : une bille réveille la souris, dont la roue entraîne un train
  d'engrenages jusqu'à un moteur.
- **Le chat et la pelote** (cuisine) : le chat bondit sur ce qui bouge ; il faut lui faire
  renverser une pile de dominos en lui montrant un ballon.
- **Couper le lien** (atelier) : un ballon retenu par une corde ; des ciseaux mobiles la
  tranchent pour qu'il crève un ballon plus haut.
- **Accroche-cœur** (usine) : une corde de pendule qui s'enroule autour d'un poteau, ce qui
  raccourcit son rayon et change sa trajectoire.
- **À l'abri du vent** (espace) : un vent fort ; il faut poser des planches pour protéger un
  ballon et le laisser monter droit.
- **Un monde « Jardin »** : eau, vent, animaux et contrepoids, avec cinq niveaux plus longs
  combinant les pièces des mondes précédents.
- **Niveaux « défi »** après chaque monde : peu de pièces, gros décor, une seule solution
  propre, pour les joueurs qui ont toutes les étoiles.

## Confort de jeu

- Bouton d'accélération de la simulation (x2, x4) et mode pause.
- Trajectoire fantôme du dernier essai, pour ajuster une pose sans tout revoir.
- Indices progressifs : un premier indice vague, puis la position d'une pièce clé, puis la
  solution complète, en échange des étoiles du niveau.
- Record personnel par niveau (temps et pièces), affiché sur sa vignette.
- Copier-coller d'une pièce posée (Ctrl+C, Ctrl+V) et sélection multiple.
- Prise en charge du tactile, pour une future version mobile.

## Éditeur et communauté

- Choix de la gravité et du vent dans l'éditeur, comme dans le bac à sable.
- Galerie de niveaux partagés, triée par difficulté mesurée (nombre d'essais avant victoire).

## Contenu et rejouabilité

- D'autres animaux aux réactions simples : un chien qui court après la balle, un oiseau qui
  s'envole au bruit.
- Défis quotidiens : un niveau du jeu avec une contrainte en plus (sans tel type de pièce, en
  moins de x secondes).
- Pièces à venir : entonnoir, tuyau qui guide les billes, aimant qui repousse, bougie qui fait
  éclater un ballon à distance.

## Présentation

- Particules : éclats du ballon, fumée du canon, poussière des chocs.
- Écrasement et étirement des objets lors des impacts.
- Musique d'atelier discrète, avec un réglage de volume séparé des effets.
- Sons continus pour le tapis et le ventilateur.
- Montrer l'ombre du vent derrière les obstacles, pour que l'abri se voie avant de lancer.
- Interface traduite, en commençant par l'anglais.
- Options d'accessibilité : couleurs de canaux adaptées, réduction des animations (dont le
  balayage entre les niveaux).

## Technique

- Rechercher l'origine de l'avertissement « ObjectDB instances leaked » des scripts de test.
- Réduire la variation de durée observée sur le niveau Dominos.
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

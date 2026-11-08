# Idées d'améliorations

Pistes pour la suite de Bric-à-Brac, groupées par thème et sans engagement. Dans chaque
section, les idées les plus utiles ou les moins coûteuses viennent en premier.

## Priorité : à valider en jouant

Le jeu n'a pour l'instant été vérifié que par des tests automatiques.

- Faire essayer les 31 niveaux à de vrais joueurs et noter où ils bloquent.
- Revoir la difficulté de la Catapulte et du Pendule, dont les zones gagnantes sont étroites.
- Régler en jouant le chat, l'élastique et la corde qui s'accroche aux obstacles, jusqu'ici
  réglés seulement par des tests.
- Vérifier que la nouvelle solution de la Bouée (ventilateur incliné) se trouve sans l'indice.
- Écouter les sons en situation, surtout le volume des chocs répétés.

## Nouveaux niveaux

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

- Mesurer la difficulté de la galerie à partir des essais de tous les joueurs, ce qui demande
  un serveur ; elle est aujourd'hui donnée par l'auteur ou déduite de sa solution.

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

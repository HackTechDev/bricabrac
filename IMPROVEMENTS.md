# Idées d'améliorations

Pistes pour la suite de Bric-à-Brac, groupées par thème et sans engagement. Dans chaque
section, les idées les plus utiles ou les moins coûteuses viennent en premier.

## Priorité : à valider en jouant

Le jeu n'a pour l'instant été vérifié que par des tests automatiques.

- Faire essayer les 46 niveaux à de vrais joueurs et noter où ils bloquent.
- Revoir la difficulté de la Catapulte et du Pendule, dont les zones gagnantes sont étroites.
- Régler en jouant le chat, l'élastique et la corde qui s'accroche aux obstacles, jusqu'ici
  réglés seulement par des tests.
- Vérifier que la nouvelle solution de la Bouée (ventilateur incliné) se trouve sans l'indice.
- Écouter les sons en situation, surtout le volume des chocs répétés, le ronronnement continu
  du tapis et du ventilateur, et la musique sur une longue partie (la boucle dure 20 s).
- Juger en jouant si l'écrasement aux chocs et la poussière aident à lire la machine ou la
  brouillent, et si l'ombre du vent et celle des ventilateurs restent lisibles sur chaque fond de
  monde (faut-il aussi dessiner la bande de souffle à l'atelier ?).
- Essayer l'entonnoir, le tuyau coudé, l'aimant répulsif et la bougie dans le bac à sable avant
  de bâtir des niveaux autour d'eux : taille de l'ouverture, vitesse de sortie du coude, délai
  de chauffe de la bougie.
- Régler l'obscurité du grenier en jouant : opacité du voile, taille du halo du pointeur, portée
  de la lampe de poche, seuil de la cellule et du chat.

## Nouveaux niveaux

- D'autres niveaux pour la cellule ailleurs qu'au grenier : elle marche dans tous les mondes,
  avec une lampe de poche.

## Confort de jeu

- Avancer pas à pas pendant la pause (une touche = un pas de simulation), pour comprendre un
  choc trop rapide, et un ralenti ×0,5 à côté de ×2 et ×4.
- Comparer deux essais : garder la trace de l'avant-dernier en plus de la dernière, d'une autre
  couleur.
- Prise en charge du tactile, pour une future version mobile.

## Éditeur et communauté

- Vérifier dans l'éditeur, avant l'enregistrement, que le niveau ne se gagne pas seul, comme le
  fait `test_levels.gd`.
- Permettre de donner un nom et un objectif en anglais à un niveau personnel, et les garder
  dans le code de partage.
- Mesurer la difficulté de la galerie à partir des essais de tous les joueurs, ce qui demande
  un serveur ; elle est aujourd'hui donnée par l'auteur ou déduite de sa solution.

## Contenu et rejouabilité

- Un mode contre la montre : enchaîner les niveaux d'un monde, temps total comparé au record.
- Des succès simples (tous les défis, aucun indice dans un monde, une machine de plus de
  20 pièces dans le bac à sable), affichés sur l'écran titre.
- D'autres animaux aux réactions simples : un chien qui court après la balle, un oiseau qui
  s'envole au bruit.
- Défis quotidiens : un niveau du jeu avec une contrainte en plus (sans tel type de pièce, en
  moins de x secondes).
- Des niveaux autour du tuyau droit et de la bougie que le vent souffle.

## Présentation

- Dessiner l'ombre des objets dans le faisceau des lampes de poche : la cellule et le chat en
  tiennent compte, mais le voile du grenier ne la montre pas encore.
- Atténuer la musique pendant la simulation et la remonter à l'atelier, pour mieux entendre la
  machine.
- Une musique par monde, sur la même trame que celle de l'atelier.
- Faire relire la traduction anglaise par un anglophone, puis ajouter d'autres langues
  (un fichier `i18n/<code>.json` et une ligne dans `Lang.LANGUAGES`).
- Changer de langue sans revenir à l'écran titre, en rafraîchissant les textes en place.
- Traduire aussi le tutoriel écrit (`TUTORIAL.md`) et le README.
- D'autres options d'accessibilité : taille du texte, commandes entièrement au clavier.

## Technique

- Dans le bac à sable, la barre du haut déborde : avec les boutons Gravité et Vent, l'objectif
  passe sur quatre lignes, la barre double de hauteur et Pause, ×1 et Lancer glissent sous le
  panneau des pièces. Raccourcir l'objectif ou regrouper gravité et vent dans un menu.
- Enregistrer les volumes dès qu'un curseur bouge : ils ne le sont aujourd'hui qu'à la
  fermeture de la fenêtre d'options, et se perdent si l'on quitte le jeu avant.
- Garder la musique calculée quand la scène se recharge (changement de langue) : elle est
  aujourd'hui recomposée, avec près d'une seconde de silence.
- Détecter automatiquement, dans `test_levels.gd`, les surfaces fixes qui se chevauchent à la
  même hauteur : un objet posé sur la jointure touche deux formes, dans un ordre qui change
  d'un essai à l'autre (c'était la cause de la variation de durée du niveau Dominos).
- Signaler dans `test_levels.gd` les solutions dont la durée varie de plus de 0,2 s sur leurs
  8 essais, signe d'une machine fragile.
- Lancer les tests automatiquement sur GitHub Actions à chaque envoi, `test_render.gd` compris
  avec un affichage virtuel (Xvfb).
- Alléger le vent et les cordes au-delà de 100 objets (voir « Performances » dans le README) :
  un seul rayon pour un corps à découvert, ne chercher les coins d'une corde que si ses segments
  ont bougé.

## Diffusion

- Préparer les exports Linux et Windows. La version web existe (voir le README) : l'essayer
  dans plusieurs navigateurs, mesurer l'arrêt dû au calcul de la musique au démarrage, et
  vérifier le son, la sauvegarde et la galerie en ligne.
- Publier une démo jouable sur itch.io, avec une page en français et en anglais, pour
  recueillir des retours.
- Ajouter au README un GIF d'une machine en marche, fait avec « Filmer en GIF ».

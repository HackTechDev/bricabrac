# Fonctionnalités

Liste de tout ce que propose Bric-à-Brac. Le détail des règles et des commandes est dans le
[tutoriel](TUTORIAL.md), les pistes pour la suite dans [IMPROVEMENTS.md](IMPROVEMENTS.md).

## Principe

- Jeu de puzzle physique en 2D : on dispose des pièces dans un atelier, on lance la simulation,
  et la réaction en chaîne doit atteindre l'objectif du niveau.
- Objectifs : déposer un objet dans un panier (où il doit rester une demi-seconde), allumer une
  lampe ou faire éclater un ballon. Un niveau peut en combiner plusieurs.
- Simulation déterministe : une même disposition donne toujours le même résultat, quels que soient
  l'ordre de pose et la vitesse de simulation.
- Tout est dessiné et composé par le code : pièces, décor, sons et musique, sans fichier
  d'image ni de son.

## Contenu

- **46 niveaux** répartis en **six mondes**, chacun avec sa couleur de fond :
  - l'**atelier**, 12 niveaux : les bases ;
  - la **cuisine**, 8 niveaux : minuteries, bac d'eau, souris, chat, bougie ;
  - l'**usine**, 7 niveaux : engrenages, aimants, ventilation, chariot, tri ;
  - l'**espace**, 6 niveaux : gravité faible, portails, vent solaire ;
  - le **jardin**, 6 niveaux : plusieurs mécanismes enchaînés ;
  - le **grenier**, 7 niveaux : plongé dans le noir, éclairé par des lampes de poche ; la
    cellule y réagit à la lumière et le chat n'y voit que ce qui est éclairé.
- Un **niveau défi** clôt chaque monde : peu de pièces, presque aucune marge. Il reste fermé tant
  que les autres niveaux du monde n'ont pas toutes leurs étoiles.
- Des niveaux à **physique particulière** : gravité faible ou forte, vent permanent.
- **Tutoriel intégré** dans les niveaux 1, 2, 6 et 7 : des bulles guident pas à pas, entourent
  l'élément à utiliser et avancent seules dès que l'étape est faite.
- Chaque niveau a une **introduction**, un **objectif** affiché en haut et un **indice**.

## Les pièces

40 sortes de pièces, chacune avec une infobulle qui explique son rôle et ses réglages.

- **Guidage :** planche, ressort, tapis roulant, bascule, entonnoir, tuyau coudé, tuyau droit
  de longueur réglable.
- **Objets mobiles :** bille, balle rebond, boulet, caisse, domino, ballon.
- **Mécanismes :**
  - plaque et interrupteur ;
  - minuterie (délai de 0,5 à 15 s) ;
  - trappe et porte ;
  - ciseaux qui coupent les cordes ;
  - aimant et aimant répulsif ;
  - moteur et engrenages ;
  - portails ;
  - bac d'eau, avec poussée d'Archimède ;
  - ventouse ;
  - chariot sur rail ;
  - souris dans sa roue ;
  - chat qui bondit sur ce qui bouge ;
  - canon ;
  - pointes ;
  - bougie qui fait éclater les ballons, et que le vent souffle ;
  - lampe de poche ;
  - cellule photoélectrique, qui allume son canal à la lumière (ou quand on la coupe) ;
  - lampe.
- **Liens :** corde (avec poulies, mou réglable, accroche aux coins des obstacles) et élastique
  (tension de départ réglable, de quoi faire une fronde).
- **Objectif :** panier.
- **Canaux 0 à 3 :** une plaque, un interrupteur ou une minuterie met en marche toutes les pièces
  de son canal, sans câble. Le canal 0 fonctionne en permanence.
- **Vent :** le vent des niveaux et le souffle des ventilateurs s'arrêtent aux obstacles. Les zones
  abritées sont assombries dès l'atelier, pour le vent du niveau comme pour chaque ventilateur.

## Construire

- Glisser-déposer depuis le bac, qui indique combien il reste de chaque pièce.
- Pièce rouge quand elle n'a pas la place ; lâchée là, elle revient au bac ou à sa position.
- Grille de 10 px ; les flèches décalent la sélection d'un cran (de 5 avec Maj).
- Rotation (R, Maj+R, molette), miroir (F), changement de canal (C), réglages propres à certaines
  pièces (délai, mou, tension, bras d'engrenage).
- Sélection multiple : Maj+clic, cadre tracé sur une zone vide, Ctrl+A. Un groupe se déplace, se
  copie et se retire d'un coup.
- Copier-coller (Ctrl+C, Ctrl+V) sous la souris, cordes comprises.
- Menu au clic droit sur une pièce : pivoter, miroir, canal, allonger, raccourcir, copier,
  retirer.
- Panneau d'actions sous le bac : Annuler, Rétablir, Pivoter, Miroir, Canal, Retirer.
- Annuler et rétablir sans limite, par niveau (Ctrl+Z, Ctrl+Y).
- « Tout retirer » vide le plateau des pièces du joueur.
- Le décor du niveau ne bouge pas ; seules les pièces du joueur se modifient.

## Lancer la machine

- Lancer et arrêter (Espace) ; à l'arrêt, tout reprend sa place de départ.
- Pause (P) et vitesse ×1, ×2 ou ×4 (V), sans changer le résultat.
- Chronomètre à cadran, avec le temps à battre en doré, et sous le temps le nombre d'essais
  du niveau (lancements de la machine, gardés d'une partie à l'autre).
- Trace du dernier essai en pointillés (dorée pour l'objectif), masquée par défaut et affichée
  avec T.
- Obscurité du grenier : un voile que percent les faisceaux des lampes de poche, les lampes
  allumées, les bougies et, à l'atelier, un halo autour du pointeur.

## Progression

- Trois objectifs bonus par niveau, une étoile chacun : **Économe** (pas plus de pièces que la
  solution de référence), **Rapide** (avant un temps donné), **Complet** (toutes les pièces du bac).
- Records par niveau : meilleur temps et plus petit nombre de pièces ; un record battu est annoncé.
- Indices en trois paliers : un texte gratuit, puis l'emplacement d'une pièce clé (une étoile de
  moins), puis toute la solution (plus de nouvelle étoile). Chaque palier payant demande
  confirmation.
- Écran de sélection : une vignette par niveau, rangées par monde, avec état, étoiles et record.
- Sauvegarde automatique de la progression, des réglages et de la machine posée dans chaque niveau.
- Écran de victoire : étoiles gagnées, niveau suivant, revoir ou filmer la machine, partager sa
  solution.

## Bac à sable et éditeur

- **Bac à sable :** toutes les pièces en quantité illimitée, sans objectif ; gravité (normale,
  ×0,4, ×0,1, ×1,8) et vent (aucun, droite, gauche, haut) réglables.
- **Éditeur de niveaux :**
  - le décor se pose avec toutes les pièces ;
  - nom, objectif à atteindre (G), inventaire du joueur (0 à 9 par pièce) ;
  - gravité (×0,1 à ×2) et vent (huit directions, force 30 à 300) ;
  - « Essayer » joue le niveau tel que le verra le joueur ;
  - « Enregistrer » le range dans « Mes niveaux » ;
  - un niveau doit être résolu par son auteur pour être partagé, et toute retouche annule cette
    preuve ;
  - « Modifier », « Supprimer » et « Nouveau » ; le brouillon est gardé entre deux parties.
- **Niveaux officiels** (jeu lancé depuis ses sources) : « Ouvrir (jeu)… » et « Écrire (jeu)… »
  lisent et écrivent les fichiers de `levels/`, avec leur solution et leur tutoriel.

## Partage et galerie

- Codes de partage `BAB1:…` à copier-coller, ou fichiers `.bab`, pour un niveau ou une solution.
- Import vérifié : le jeu rejoue en coulisse la solution de l'auteur avant d'accepter un niveau.
- **Galerie des joueurs :**
  - niveaux d'exemple livrés avec le jeu ;
  - auteur, difficulté (★ à ★★★), état et nombre d'essais de chaque niveau ;
  - tri par difficulté ou par date ;
  - « Actualiser en ligne » télécharge la dernière version de la galerie ;
  - « Proposer mon niveau… » ouvre une demande d'ajout préremplie sur le dépôt.
- **Revoir et filmer** une solution gagnante : rejouer, enregistrer en GIF animé ou en vidéo AVI
  (MJPEG, 30 images par seconde), et ouvrir le dossier des enregistrements.

## Présentation

- Écran titre animé : engrenages, tapis, bille, lampe. Il affiche la progression et ouvre Jouer
  (ou Continuer), Choisir un niveau, Bac à sable, Galerie, Éditeur, Options et Quitter.
- Transition entre les niveaux : balayage et carte qui annonce le monde et le nom du niveau.
- Particules décoratives :
  - éclats des ballons ;
  - fumée du canon ;
  - poussière des chocs ;
  - gouttes du bac d'eau ;
  - étincelles des engrenages.
- Écrasement des objets au choc.
- Sons synthétisés : chocs selon la matière et la force (métal, bois, choc sourd), pose,
  retrait, refus, lancement et arrêt, ressort, ciseaux, ballon qui éclate, lampe, miaulement du
  chat, couinement de la souris, ronronnement continu des tapis et des ventilateurs.
- Musique d'atelier composée par le code.
- Ligne de messages en bas de l'écran, qui guide et explique chaque refus.

## Options et accessibilité

- Volumes séparés des effets et de la musique, et coupure de tout le son (M).
- Langue : français ou anglais, pour toute l'interface, les niveaux et le tutoriel intégré.
- Couleurs de canaux adaptées au daltonisme (orange, bleu ciel, violet).
- « Réduire les animations » : sans balayage, particules ni mouvements décoratifs.
- Quitter avec confirmation : bouton de l'écran titre, de l'écran de sélection, Ctrl+Q ou croix
  de la fenêtre.

## Pour les développeurs

- Niveaux en fichiers texte lisibles (`levels/NN_id.cfg`), avec leur solution de référence.
- Tests automatiques :
  - chaque niveau est faisable, ne se gagne pas seul et tient son temps « Rapide » ;
  - interface à la souris et au clavier ;
  - pièces ;
  - corde et sons ;
  - tutoriel ;
  - traduction ;
  - rendu des vignettes.
- Outils :
  - mesure des performances (`bench_perf.gd`) ;
  - recherche de zones gagnantes (`sweep.gd`) ;
  - captures d'écran (`capture.gd`).
- Code sous licence MIT.

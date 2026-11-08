# Tutoriel

Bienvenue dans Bric-à-Brac ! Chaque niveau pose un objectif : déposer une bille dans un panier,
allumer une lampe, faire éclater un ballon. Pour y arriver, tu disposes quelques pièces dans
l'atelier, puis tu lances la machine et tu regardes ce qui se passe.

Le jeu contient aussi un tutoriel intégré : des bulles te guident pas à pas dans les niveaux 1, 2,
6 et 7, qui présentent chacun une nouvelle notion. Il s'affiche de lui-même tant que le niveau n'est
pas terminé, et « Passer le tutoriel » le ferme. Le bouton **Indice** le relance à tout moment.

Ce document reprend les mêmes explications, pour les lire à tête reposée.

## Lancer le jeu

Ouvre le projet dans Godot 4.7 et appuie sur F5, ou lance cette commande depuis le dossier du jeu,
avec `GODOT` pointant vers l'exécutable de Godot :

    $GODOT --path .

Le jeu s'ouvre sur l'**écran titre**. **Jouer** (ou **Continuer** si tu as déjà commencé) t'emmène
au premier niveau que tu n'as pas encore résolu ; Entrée ou Espace font de même. Tu peux aussi
choisir un niveau, ouvrir le bac à sable ou l'éditeur de niveaux. Le bas de l'écran rappelle ta
progression et tes étoiles. Pour y revenir en cours de partie, appuie sur Échap quand rien n'est
sélectionné, ou utilise le bouton « Écran titre » de l'écran de sélection.

À chaque changement de niveau, l'écran précédent s'efface en balayage et une carte annonce le
monde et le nom du niveau. Tu peux commencer à construire sans attendre la fin de l'animation.

## L'écran

- **En haut :** le bouton du niveau en cours, qui ouvre l'écran de sélection, l'objectif, puis les boutons Son, Indice, Tout retirer, le chronomètre et Lancer.
- **Au centre :** le plateau, où tu construis ta machine.
- **À droite :** le bac des pièces disponibles et, dessous, les actions sur la pièce sélectionnée.
- **En bas :** une ligne de messages, qui te guide et explique pourquoi une action est refusée.

Survole une pièce un instant, dans le bac ou sur le plateau, pour afficher son rôle et ses réglages.

## Ta première machine

Le niveau 1, *Première pente*, te demande d'amener la bille dans le panier doré.

1. **Lance une première fois**, avec le bouton Lancer ou la touche Espace. La bille tombe tout droit
   et n'atteint pas le panier.
2. **Reviens à l'atelier** avec Arrêter ou Espace. Tout reprend sa place de départ.
3. **Prends une planche :** glisse-la depuis le bac et lâche-la sous la bille, un peu à droite et
   un peu au-dessus de la mi-hauteur du plateau.
4. **Incline-la :** avec la planche sélectionnée, appuie deux fois sur R. Chaque appui la fait
   pivoter de 15°, et sa partie droite doit descendre vers le panier.
5. **Lance de nouveau.** La bille rebondit sur la planche, prend de la vitesse et file vers le panier.

Si elle tombe à côté, reviens à l'atelier, déplace la planche de quelques cases et réessaie. Tâtonner
fait partie du jeu : rien n'est perdu quand une tentative échoue, et tes pièces restent en place.
Le niveau est gagné quand la bille reste une demi-seconde dans le panier.

## Les commandes

| Action | Commande |
| --- | --- |
| Placer une pièce | La glisser depuis le bac |
| Sélectionner ou déplacer une pièce posée | Clic gauche, en maintenant pour déplacer |
| Pivoter, ou régler le délai d'une minuterie | R ou molette ; Maj+R dans l'autre sens |
| Retourner (miroir) | F |
| Changer de canal | C |
| Retirer une pièce | Clic droit, ou sélection puis Suppr |
| Annuler | Ctrl+Z, ou bouton Annuler |
| Rétablir | Ctrl+Y ou Ctrl+Maj+Z, ou bouton Rétablir |
| Lancer ou arrêter | Espace |
| Couper le son | M |
| Choisir un niveau | Tab, ou le bouton en haut à gauche |
| Revenir à l'écran titre | Échap, quand rien n'est sélectionné ni en cours |
| Marquer l'objectif (éditeur) | G |

Les boutons du panneau de droite font la même chose que R, F et C. Ils restent grisés quand la pièce
sélectionnée ne propose pas l'action.

Une pièce devient rouge quand elle n'a pas la place : si tu la lâches là, elle retourne dans le bac
ou reprend sa position précédente. Seules tes pièces se modifient : le décor et les objets déjà
présents dans le niveau restent en place.

## Les pièces

**Pour guider les objets**

- **Planche :** rampe fixe, à orienter comme tu veux.
- **Ressort :** renvoie tout objet à la même vitesse dans l'axe de sa face verte, quel que soit son
  poids. L'incliner suffit à viser.
- **Tapis :** entraîne ce qui se pose dessus. Le miroir inverse son sens.
- **Bascule :** démarre penchée d'un côté. Une charge qui tombe sur le côté haut catapulte ce qui
  repose sur le côté bas. Le miroir change le côté bas.

**Les objets mobiles**

- **Bille :** polyvalente, en acier.
- **Balle rebond :** légère et très élastique, donc parfois imprévisible.
- **Boulet :** très lourd, il ne rebondit presque pas.
- **Caisse :** elle glisse plus qu'elle ne roule.
- **Domino :** se renverse et transmet le choc au suivant.
- **Ballon :** monte tout seul et éclate sur les pointes.

**Les mécanismes**

- **Plaque :** un objet qui la touche allume son canal. Elle ne l'éteint jamais.
- **Interrupteur :** chaque objet qui heurte son levier allume ou éteint son canal. Un objet qui
  rebondit sur le levier ne compte qu'une fois.
- **Ventilateur :** pousse fort ce qui est léger et presque pas ce qui est lourd. Son souffle
  s'arrête au premier obstacle : ce qui est caché derrière une planche ou un mur n'est pas poussé.
  Incliné, il peut souffler par-dessus un rebord.
- **Minuterie :** allume son canal un certain temps après le lancement. R et la molette règlent
  ce délai, de 0,5 à 15 secondes.
- **Trappe et porte :** s'ouvrent quand leur canal s'allume et se referment quand il s'éteint. La
  trappe bascule vers le bas et lâche ce qu'elle porte ; la porte s'écarte vers la droite, ou vers
  la gauche après un miroir.
- **Ciseaux :** quand leur canal s'allume, ils coupent toute corde qui passe entre leurs lames
  (le cadre clair au-dessus du socle). Avec une minuterie, ils déclenchent un mécanisme à retardement.
- **Aimant :** attire le boulet et la bille jusqu'à 260 px de ses pôles, mais ni le bois ni le
  caoutchouc. Le cercle clair montre sa portée. Canal 0 : toujours actif.
- **Moteur et engrenages :** le moteur fait tourner les engrenages qu'il touche, et chaque roue
  entraîne ses voisines en sens inverse. Deux roues engrènent quand leurs dents se touchent ;
  l'infobulle indique avec combien de roues une pièce engrène. Le bras de l'engrenage balaie et
  pousse les objets, et R l'oriente. Le miroir inverse le sens du moteur. Canal 0 : toujours actif.
- **Portail :** un objet qui y entre ressort par l'autre portail du même canal, à la même vitesse.
  Si les deux portails n'ont pas la même orientation, la trajectoire tourne d'autant : une bille
  qui tombe dans un portail couché ressort à l'horizontale d'un portail debout. Rien ne heurte
  un portail, et il fonctionne sans être allumé.
- **Bac d'eau :** la caisse, le domino et la balle rebond y flottent ; la bille et le boulet coulent
  lentement jusqu'au fond. L'eau freine tout ce qui la traverse, ce qui amortit une chute.
- **Ventouse :** retient le premier objet qui touche sa coupelle rouge, qu'il peut pivoter autour du
  point de contact. Sur le canal 0, elle ne le lâche jamais ; sur les canaux 1 à 3, elle le lâche
  quand son canal s'allume, par exemple avec une minuterie.
- **Chariot sur rail :** le wagonnet ne peut que rouler le long de son rail, d'un butoir à l'autre,
  et emporte ce qu'on pose dessus. Incliné avec R, le rail le fait descendre tout seul ; sinon, un
  choc ou un ventilateur le mettent en route.
- **Souris :** elle dort dans sa roue jusqu'à ce qu'un objet heurte la roue ou que son canal
  s'allume. Réveillée, elle court sans s'arrêter, et sa roue entraîne les engrenages qu'elle touche,
  comme un moteur. Le miroir change le sens de sa course.
- **Chat :** assis, il guette le côté où il regarde. Dès qu'un objet passe en mouvement à moins de
  320 px, il bondit dessus en visant l'endroit où l'objet sera à son arrivée, puis se remet en
  position. Le miroir le fait regarder de l'autre côté.
- **Canon :** tire une seule bille quand son canal s'allume. Il suffit de le faire pivoter pour viser.
- **Pointes :** solides pour tout le monde, fatales pour les ballons.
- **Lampe :** s'allume avec son canal. C'est souvent l'objectif.

## Les canaux

Une plaque met en marche toutes les pièces qui partagent son numéro de canal, sans aucun câble à
tirer. Le numéro s'affiche sur la pastille colorée de chaque pièce, et la touche C le change.

- **Plaque, canon et lampe :** canaux 1 à 3.
- **Portail :** canaux 1 à 3, mais le numéro ne sert qu'à relier deux portails entre eux.
- **Tapis, ventilateur, aimant et moteur :** canaux 1 à 3, ou canal 0 pour fonctionner en permanence.

Par exemple, pour déclencher un canon, pose une plaque là où un objet va tomber, puis mets la plaque
et le canon sur le même numéro.

## Gravité et vent

Certains niveaux changent les lois de l'atelier, ce que rappelle la fin de l'objectif en haut de
l'écran :

- **Gravité faible ou forte :** tout tombe plus lentement ou plus vite, y compris les ballons qui
  montent moins vite. Les sauts et les tirs de canon portent donc plus ou moins loin.
- **Vent permanent :** des traînées traversent le plateau dans son sens. Il pousse les objets en
  proportion de leur taille rapportée à leur poids : il emporte un ballon, dévie une balle rebond et
  touche à peine le boulet. Un objet posé sur un support résiste grâce au frottement. Il entre par
  le bord du plateau et s'arrête aux obstacles : derrière un mur, on est à l'abri, et un objet à
  moitié caché ne reçoit qu'une partie de la poussée.

## Les cordes et les poulies

La corde relie deux pièces, avec des poulies en chemin si besoin. Elle se pose en plusieurs clics :

1. Pose d'abord tes poulies sur le plateau.
2. Clique sur **Corde** dans le bac.
3. Clique sur le premier objet.
4. Clique sur les poulies, dans l'ordre où la corde doit les traverser.
5. Clique sur le second objet.

Échap ou clic droit annule la pose en cours. Pour retirer une corde déjà posée, fais un clic droit
dessus. Retirer une pièce ou une poulie renvoie aussi au bac les cordes qui y sont liées.

À retenir :

- **Elle tire mais ne pousse pas :** elle se pose tendue et ne peut pas dépasser sa longueur. Elle
  se détend si ses deux bouts se rapprochent.
- **Le mou se règle :** sélectionne une corde, puis R ou la molette pour ajouter ou retirer du mou
  par pas de 20 px. Un objet retenu par une corde détendue tombe librement avant d'être rattrapé.
- **Le plus lourd l'emporte :** de part et d'autre d'une poulie, le boulet fait monter une bille.
- **Elle s'enroule sur les poulies :** elle passe du côté où elle tourne, sur le bord de la roue,
  et la fait tourner en coulissant.
- **Elle se prend aux obstacles :** en mouvement, elle accroche les coins de ce qu'elle rencontre et
  les contourne ; un pendule qui frôle un poteau repart sur un rayon plus court. Elle tire aussi sur
  les objets mobiles qu'elle soutient : tendue entre deux supports, elle retient une bille comme un
  hamac. Ce qu'elle traverse déjà quand tu lances la machine ne la gêne pas.
- **Le point d'attache compte :** sur une planche, une bascule ou un domino, il dépend de l'endroit
  où tu cliques. Cela permet par exemple de régler un pendule.
- **Il faut au moins un objet mobile :** une corde entre deux pièces fixes est refusée.

L'**élastique** se pose exactement comme la corde, mais il s'étire : au-delà de sa longueur de
repos, il tire d'autant plus fort qu'il est allongé, comme un ressort. Sélectionné, R ou la molette
règlent sa tension de départ, de 0 à 70 % par pas de 10 : tendu, il ramène vivement ce qu'il retient,
de quoi fabriquer une fronde. Il s'amincit à mesure qu'il s'étire.

## Les niveaux

Les 18 niveaux sont regroupés en quatre mondes, chacun avec sa couleur de fond. Tous sont accessibles
dès le départ depuis l'écran de sélection, qu'ouvrent le bouton en haut à gauche ou la touche Tab.
Chaque niveau y a sa vignette, avec son état : « À faire », ou « Terminé » suivi de ses étoiles.
Clique sur une vignette pour jouer ce niveau ; Échap ferme l'écran.
Le bouton **Indice** donne un coup de pouce sans tout révéler.

**L'atelier**, pour apprendre les bases :

1. **Première pente :** la planche.
2. **Par-dessus le mur :** le ressort.
3. **Effet domino :** transmettre un choc au-delà d'une fosse.
4. **Courant d'air :** le ventilateur et le ballon.
5. **Catapulte :** la bascule, un niveau plus exigeant.
6. **Coup de canon :** les canaux et la visée.
7. **Contrepoids :** les poulies et la corde.
8. **Le pendule :** la corde comme balancier.
9. **Réaction en chaîne :** une machine complète, avec plusieurs mécanismes en cascade.

**La cuisine**, avec ses minuteries et son bac d'eau :

10. **Le minuteur :** la minuterie et la trappe.
11. **La bouée :** faire flotter une caisse jusqu'à une plaque.
12. **Le batteur :** le moteur et l'engrenage.

**L'usine**, avec ses machines et sa ventilation :

13. **Train d'engrenages :** relier un moteur lointain par des roues.
14. **Le palan magnétique :** soulever une bille avec l'aimant.
15. **Ventilation :** un vent permanent contrarie le ballon.

**L'espace**, où la gravité est faible :

16. **Bond lunaire :** un saut sur ressort qui porte très loin.
17. **Le sas :** les portails.
18. **Tir en orbite :** canon, minuterie et portails pour franchir un mur.

## Les objectifs bonus

Chaque victoire fait le point sur trois défis facultatifs, qui rapportent chacun une étoile :

- **Économe :** gagner avec au plus autant de pièces que la solution de référence.
- **Rapide :** gagner avant un temps donné, compté depuis le lancement. Le **chronomètre**, à
  côté de Lancer, mesure ce temps : son cadran fait un tour en 10 secondes, l'arc doré marque le
  temps à battre, et le temps reste doré tant que tu es dans les clous. Il passe au vert à la
  victoire et garde le dernier temps quand tu arrêtes la machine.
- **Complet :** gagner en posant toutes les pièces du bac. Ce défi n'existe que si le bac contient
  plus de pièces qu'il n'en faut.

Économe et Complet ne s'obtiennent pas avec la même machine : il faut rejouer le niveau. Les étoiles
gagnées restent acquises, et l'écran de sélection et le bouton du niveau les affichent.

## Le bac à sable

La dernière vignette de l'écran de sélection, **Bac à sable**, n'a pas d'objectif. Toutes les pièces y
sont disponibles en quantité illimitée (« ∞ »), y compris le panier et la lampe. Deux boutons
apparaissent en haut de l'écran :

- **Gravité :** normale, ×0,4, ×0,1 ou ×1,8.
- **Vent :** aucun, vers la droite, vers la gauche ou vers le haut.

Ces réglages ne changent qu'à l'atelier, pas pendant la simulation. Comme dans les niveaux, ta
machine est sauvegardée et Ctrl+Z annule tes actions.

## L'éditeur de niveaux

La vignette **Éditeur de niveaux**, dans « Création libre », ouvre un plan de travail où toutes les
pièces sont disponibles sans limite. Tout ce que tu y poses forme le **décor** de ton niveau. Le
panneau « Éditeur de niveaux », sous le bac, règle le reste :

1. **Nom et objectif :** le nom du niveau et la phrase d'objectif affichée au joueur.
2. **Objectif (G) :** sélectionne un panier, une lampe ou un ballon et appuie sur G. Une étoile
   dorée le signale ; il en faut au moins un. Pour une lampe, pense à poser de quoi l'allumer.
3. **Inventaire… :** les pièces offertes au joueur, de 0 à 9 de chaque sorte.
4. **Physique… :** la gravité, de ×0,1 à ×2, et le vent, dans l'une des huit directions avec
   une force de 30 à 300 (à 120, il emporte un ballon). Le bouton résume le réglage en cours, qui
   est gardé avec ton brouillon. Les deux boutons du haut proposent aussi les réglages rapides du
   bac à sable.
5. **Essayer :** joue ton niveau tel que le verra le joueur. « Retour à l'éditeur » ramène au
   plan de travail, intact.
6. **Enregistrer :** range le niveau dans le monde « Mes niveaux » de l'écran de sélection.

Un niveau ne peut être partagé que si tu l'as **résolu toi-même**. Gagne-le avec « Essayer » :
le panneau affiche alors « ✔ Résolu par toi » et ta solution est enregistrée avec le niveau. Toute
retouche du décor, de l'inventaire, de la gravité ou du vent annule cette preuve, et il faut le
gagner de nouveau. Dans l'écran de sélection, un niveau qui n'a pas été résolu porte la mention
« Non vérifié ».

Le bouton **Modifier**, en haut d'un de tes niveaux, le rouvre dans l'éditeur ; **Supprimer** l'efface
de « Mes niveaux » et **Nouveau** vide le plan de travail. Ton brouillon est gardé entre deux parties.

Chacun de tes niveaux est un fichier texte du dossier `niveaux`, dans les données du jeu (à côté
du dossier `enregistrements`). Tu peux le copier pour le sauvegarder ou le transmettre ; pour le
partager avec sa vérification, préfère toutefois « Partager le niveau… ».

**Niveaux du jeu.** Quand le jeu est lancé depuis ses sources (Godot ouvert sur le projet), deux
boutons de plus permettent de travailler sur les niveaux officiels du dossier `levels/` :

- **Ouvrir (jeu)…** liste ces niveaux et en charge un dans l'éditeur, avec sa solution, qui sert
  de preuve tant que rien ne change.
- **Écrire (jeu)…** demande sa fiche (identifiant, monde, introduction, indice, temps de
  l'objectif « Rapide ») et écrit le fichier. Un nouveau niveau est numéroté après les autres ; un
  niveau ouvert garde son fichier, ou est renommé si son identifiant change. Comme pour le partage,
  il faut l'avoir gagné avec « Essayer » : sa solution est enregistrée avec lui. Le tutoriel d'un
  niveau ouvert est conservé.

## Partager

Les niveaux et les solutions se partagent sous forme d'un **code** à copier-coller (il commence
par `BAB1:`) ou d'un **fichier `.bab`** contenant ce code.

- **Partager un niveau :** dans l'éditeur, « Partager le niveau… ». Il faut l'avoir résolu toi-même
  auparavant : ta solution part avec le niveau.
- **Partager une solution :** à la victoire, « Partager ma solution… ». Le code ne vaut que pour ce
  niveau, dans cette version.
- **Importer :** dans l'écran de sélection, « Importer un niveau… », puis colle le code ou ouvre
  le fichier. Un niveau importé est d'abord vérifié : le jeu rejoue en coulisse la solution de son
  auteur, et refuse le niveau si elle ne gagne pas, si elle dépasse l'inventaire ou si le code est
  abîmé. Une solution importée se charge dans son niveau ; il ne reste qu'à lancer la machine.

## Revoir et filmer une solution

À la victoire, trois boutons rejouent ta machine depuis le début :

- **Revoir :** la relance simplement, pour le plaisir des yeux.
- **Filmer en GIF :** l'enregistre en image animée (demi-taille, environ 12 images par seconde),
  idéale pour un message ou un forum.
- **Filmer en vidéo :** l'enregistre en vidéo AVI (MJPEG, 30 images par seconde, pleine taille),
  lisible par VLC ou ffmpeg.

L'enregistrement s'arrête une seconde après la victoire, au plus tard après 20 secondes, ou dès
que tu appuies sur « Arrêter ». Le chemin du fichier s'affiche en bas de l'écran, et « Ouvrir le
dossier des enregistrements » ouvre le dossier `enregistrements` des données du jeu.

## Conseils

- **Lance souvent :** une courte tentative renseigne mieux qu'une longue réflexion.
- **Observe avant de construire :** lance le niveau à vide pour voir ce que font les objets présents.
- **Change une seule chose à la fois :** tu comprendras mieux l'effet de chaque réglage.
- **Rien n'oblige à tout utiliser :** certains niveaux offrent plus de pièces qu'il n'en faut.
- **Il y a souvent plusieurs solutions :** si la tienne fonctionne, elle est bonne.

Ta progression, le réglage du son et les pièces posées dans chaque niveau sont sauvegardés : tu
retrouves ta machine en revenant sur un niveau ou en relançant le jeu. L'historique d'annulation, lui,
est conservé quand tu changes de niveau, mais pas quand tu quittes le jeu.

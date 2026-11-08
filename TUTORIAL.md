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

## L'écran

- **En haut :** le choix du niveau, l'objectif, puis les boutons Son, Indice, Tout retirer et Lancer.
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
- **Ventilateur :** pousse fort ce qui est léger et presque pas ce qui est lourd. Son vent traverse
  les obstacles.
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
  touche à peine le boulet. Un objet posé sur un support résiste grâce au frottement.

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
- **Elle traverse tout :** seuls ses deux bouts agissent, et elle ne heurte aucun objet.
- **Le point d'attache compte :** sur une planche, une bascule ou un domino, il dépend de l'endroit
  où tu cliques. Cela permet par exemple de régler un pendule.
- **Il faut au moins un objet mobile :** une corde entre deux pièces fixes est refusée.

## Les niveaux

Tous les niveaux sont accessibles dès le départ depuis la liste en haut à gauche, et ceux que tu as
terminés portent la mention `[OK]`. Le bouton **Indice** donne un coup de pouce sans tout révéler.

1. **Première pente :** la planche.
2. **Par-dessus le mur :** le ressort.
3. **Effet domino :** transmettre un choc au-delà d'une fosse.
4. **Courant d'air :** le ventilateur et le ballon.
5. **Catapulte :** la bascule, un niveau plus exigeant.
6. **Coup de canon :** les canaux et la visée.
7. **Contrepoids :** les poulies et la corde.
8. **Le pendule :** la corde comme balancier.
9. **Réaction en chaîne :** une machine complète, avec plusieurs mécanismes en cascade.

## Conseils

- **Lance souvent :** une courte tentative renseigne mieux qu'une longue réflexion.
- **Observe avant de construire :** lance le niveau à vide pour voir ce que font les objets présents.
- **Change une seule chose à la fois :** tu comprendras mieux l'effet de chaque réglage.
- **Rien n'oblige à tout utiliser :** certains niveaux offrent plus de pièces qu'il n'en faut.
- **Il y a souvent plusieurs solutions :** si la tienne fonctionne, elle est bonne.

Ta progression, le réglage du son et les pièces posées dans chaque niveau sont sauvegardés : tu
retrouves ta machine en revenant sur un niveau ou en relançant le jeu. L'historique d'annulation, lui,
est conservé quand tu changes de niveau, mais pas quand tu quittes le jeu.

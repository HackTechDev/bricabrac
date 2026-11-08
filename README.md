# Bric-à-Brac

Jeu de puzzle physique sous Godot 4.7 : on dispose des pièces dans un atelier, on lance la
simulation, et la réaction en chaîne doit atteindre l'objectif du niveau.

Pour découvrir le jeu, suis le [tutoriel](TUTORIAL.md). Les pistes pour la suite sont dans
[IMPROVEMENTS.md](IMPROVEMENTS.md).

## Jouer

Ouvrir le projet dans Godot, ou, avec `GODOT` pointant vers l'exécutable de Godot :

    $GODOT --path .

| Action | Commande |
| --- | --- |
| Placer une pièce | Glisser depuis le bac |
| Déplacer / sélectionner | Clic gauche sur une pièce posée |
| Pivoter | R ou molette (Maj+R : sens inverse) |
| Miroir | F |
| Changer de canal | C |
| Poser une corde | Clic sur Corde dans le bac, puis le premier objet, les poulies dans l'ordre, le second objet |
| Annuler une corde en cours | Échap, clic droit ou Ctrl+Z |
| Sélection multiple | Maj+clic, Ctrl+A |
| Copier / coller | Ctrl+C / Ctrl+V (sous la souris) |
| Retirer | Clic droit ou Suppr |
| Annuler / rétablir | Ctrl+Z / Ctrl+Y ou Ctrl+Maj+Z |
| Lancer / arrêter | Espace |
| Couper le son | M |
| Écran titre | Échap, quand rien n'est sélectionné |

## Organisation

- `scripts/board.gd` : mécanique de jeu (disposition, simulation, victoire), sans interface.
- `scripts/main.gd`, `bin_item.gd`, `part_icon.gd` : interface ; `title_screen.gd` : écran titre ;
  `level_transition.gd` : passage d'un niveau à l'autre ; `chrono.gd` : chronomètre.
- `scripts/history.gd` : historique d'annulation, par niveau.
- `scripts/tutorial.gd` : bulles du tutoriel intégré ; les étapes sont dans les fichiers de niveau.
- `scripts/parts/` : une classe par pièce, dessinée par le code. `catalog.gd` les référence.
- `scripts/parts/rope_part.gd` : contrainte de longueur de la corde, enroulée sur les poulies et accrochée aux coins des obstacles (Godot n'a pas de joint poulie en 2D).
- `scripts/sfx.gd` : sons synthétisés par le code, sans fichier audio.
- `scripts/wind.gd` : abri du vent, par lancer de rayons depuis l'amont.
- `gallery/index.cfg` : galerie de niveaux partagés (codes `BAB1:`) ; `scripts/gallery.gd` en décrit le
  format. Pour y ajouter un niveau proposé, coller son code dans une nouvelle section.
- `levels/` : les niveaux du jeu, un fichier texte par niveau (`07_contrepoids.cfg`), joués dans
  l'ordre des noms ; chacun indique son monde et sa solution. Chaque monde a sa dizaine (atelier
  01 à 19, cuisine 20, usine 30, espace 40, jardin 50), pour ajouter un niveau sans renuméroter les autres.
- `scripts/level_file.gd` : lecture et écriture de ces fichiers ; `level_data.gd` : mondes, bac à
  sable, éditeur et liste des niveaux.

## Tests

    export GODOT=/chemin/vers/Godot_v4.7.2-stable_linux.x86_64
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_levels.gd   # chaque niveau est faisable
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_ui.gd       # souris et clavier
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_rope.gd     # physique de la corde, sons
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_parts.gd    # pièces mécaniques
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_tutorial.gd # tutoriel intégré
    SWEEP=spec.json $GODOT --headless --path . --fixed-fps 120 -s tests/sweep.gd   # aide à la conception
    CAPTURE_DIR=dossier $GODOT --path . -s tests/capture.gd              # captures (affichage requis)

Pour ajouter un niveau : le construire dans l'éditeur du jeu lancé depuis les sources, le gagner
avec « Essayer », puis « Écrire (jeu)… » écrit son fichier dans `levels/` avec sa solution.
On peut aussi écrire le fichier à la main (format décrit en tête de `scripts/level_file.gd`, le
préfixe numérique fixe sa place) et chercher une large zone gagnante avec `sweep.gd`.
`test_levels.gd` vérifie ensuite que la solution gagne.

## Licence

Le code est distribué sous licence MIT : voir `LICENSE`.

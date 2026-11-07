# Bric-à-Brac

Jeu de puzzle physique sous Godot 4.7 : on dispose des pièces dans un atelier, on lance la
simulation, et la réaction en chaîne doit atteindre l'objectif du niveau.

## Jouer

Ouvrir le projet dans Godot, ou :

    /home/util01/JEUX/GODOT/Godot_v4.7.2-stable_linux.x86_64 --path .

| Action | Commande |
| --- | --- |
| Placer une pièce | Glisser depuis le bac |
| Déplacer / sélectionner | Clic gauche sur une pièce posée |
| Pivoter | R ou molette |
| Miroir | F |
| Changer de canal | C |
| Retirer | Clic droit ou Suppr |
| Lancer / arrêter | Espace |

## Organisation

- `scripts/board.gd` : mécanique de jeu (disposition, simulation, victoire), sans interface.
- `scripts/main.gd`, `bin_item.gd`, `part_icon.gd` : interface.
- `scripts/parts/` : une classe par pièce, dessinée par le code. `catalog.gd` les référence.
- `scripts/level_data.gd` : les niveaux, chacun avec une solution.

## Tests

    GODOT=/home/util01/JEUX/GODOT/Godot_v4.7.2-stable_linux.x86_64
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_levels.gd   # chaque niveau est faisable
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_ui.gd       # souris et clavier
    SWEEP=spec.json $GODOT --headless --path . --fixed-fps 120 -s tests/sweep.gd   # aide à la conception
    CAPTURE_DIR=dossier $GODOT --path . -s tests/capture.gd              # captures (affichage requis)

Pour ajouter un niveau : le décrire dans `level_data.gd`, chercher une large zone gagnante avec
`sweep.gd`, puis renseigner sa `solution` pour que `test_levels.gd` la vérifie.

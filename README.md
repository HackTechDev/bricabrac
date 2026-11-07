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
| Pivoter | R ou molette |
| Miroir | F |
| Changer de canal | C |
| Poser une corde | Clic sur Corde dans le bac, puis le premier objet, les poulies dans l'ordre, le second objet |
| Annuler une corde en cours | Échap, clic droit ou Ctrl+Z |
| Retirer | Clic droit ou Suppr |
| Annuler / rétablir | Ctrl+Z / Ctrl+Y ou Ctrl+Maj+Z |
| Lancer / arrêter | Espace |
| Couper le son | M |

## Organisation

- `scripts/board.gd` : mécanique de jeu (disposition, simulation, victoire), sans interface.
- `scripts/main.gd`, `bin_item.gd`, `part_icon.gd` : interface.
- `scripts/history.gd` : historique d'annulation, par niveau.
- `scripts/parts/` : une classe par pièce, dessinée par le code. `catalog.gd` les référence.
- `scripts/parts/rope_part.gd` : contrainte de longueur de la corde (Godot n'a pas de joint poulie en 2D).
- `scripts/sfx.gd` : sons synthétisés par le code, sans fichier audio.
- `scripts/level_data.gd` : les niveaux, chacun avec une solution.

## Tests

    export GODOT=/chemin/vers/Godot_v4.7.2-stable_linux.x86_64
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_levels.gd   # chaque niveau est faisable
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_ui.gd       # souris et clavier
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_rope.gd     # physique de la corde, sons
    SWEEP=spec.json $GODOT --headless --path . --fixed-fps 120 -s tests/sweep.gd   # aide à la conception
    CAPTURE_DIR=dossier $GODOT --path . -s tests/capture.gd              # captures (affichage requis)

Pour ajouter un niveau : le décrire dans `level_data.gd`, chercher une large zone gagnante avec
`sweep.gd`, puis renseigner sa `solution` pour que `test_levels.gd` la vérifie.

## Licence

Le code est distribué sous licence MIT : voir `LICENSE`.

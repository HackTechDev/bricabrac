# Bric-à-Brac

Jeu de puzzle physique sous Godot 4.7 : on dispose des pièces dans un atelier, on lance la
simulation, et la réaction en chaîne doit atteindre l'objectif du niveau.

Pour découvrir le jeu, suis le [tutoriel](TUTORIAL.md). La liste complète des fonctionnalités est
dans [FEATURES.md](FEATURES.md), les pistes pour la suite dans [IMPROVEMENTS.md](IMPROVEMENTS.md).

## Jouer

Ouvrir le projet dans Godot, ou, avec `GODOT` pointant vers l'exécutable de Godot :

    $GODOT --path .

| Action | Commande |
| --- | --- |
| Placer une pièce | Glisser depuis le bac |
| Déplacer / sélectionner | Clic gauche sur une pièce posée |
| Pivoter | R ou molette (Maj+R : sens inverse) |
| Miroir | F |
| Longueur (tuyau droit) | + et − |
| Changer de canal | C |
| Poser une corde | Clic sur Corde dans le bac, puis le premier objet, les poulies dans l'ordre, le second objet |
| Annuler une corde en cours | Échap, clic droit ou Ctrl+Z |
| Sélection multiple | Maj+clic, cadre tracé sur une zone vide, Ctrl+A |
| Copier / coller | Ctrl+C / Ctrl+V (sous la souris) |
| Ajuster la position | Flèches (Maj : 5 crans) |
| Menu d'une pièce | Clic droit (pivoter, miroir, canal, copier, retirer) |
| Retirer | Suppr, ou « Retirer » du menu |
| Quitter le jeu | Ctrl+Q, « Quitter » (écran titre, écran de choix), avec confirmation |
| Annuler / rétablir | Ctrl+Z / Ctrl+Y ou Ctrl+Maj+Z |
| Lancer / arrêter | Espace |
| Couper le son | M |
| Options (volumes, langue) | O |
| Écran titre | Échap, quand rien n'est sélectionné |

### Version web (HTML)

Le préréglage « Web » de `export_presets.cfg` produit une version jouable dans un navigateur, dans
`build/web/` (modèles d'exportation de Godot 4.7.2 requis) :

    $GODOT --headless --path . --export-release "Web" build/web/index.html
    cd build/web && python3 -m http.server 8000    # puis ouvrir http://localhost:8000

La page doit être servie par un serveur web (pas ouverte comme fichier). Elle n'utilise pas les
fils d'exécution, donc aucun en-tête particulier n'est nécessaire, et elle se dépose telle quelle
sur itch.io (zip du dossier). Les niveaux, la galerie et la traduction sont inclus dans le
paquet ; la musique y est composée sur le fil principal une demi-seconde après le démarrage. La
sauvegarde reste dans le navigateur, et le bouton Quitter n'y apparaît pas.

#### Analyse de l'export web

**Vérifié :**

- Le paquet `index.pck` contient les 43 niveaux de `levels/`, la galerie `gallery/index.cfg`,
  la traduction `i18n/en.json` et le shader du grenier. Vérification faite en chargeant le
  paquet dans Godot (`--main-pack`) et en listant ses dossiers.
- Le paquet exporté, lancé hors navigateur, démarre sans erreur.
- Les tests automatiques passent après les deux corrections ci-dessous.

**Corrigé pour le web :**

- **Traduction absente.** `Lang` lit `i18n/en.json` comme un fichier brut, et le préréglage
  n'exportait que `levels/*.cfg` et `gallery/*.cfg` : le choix de l'anglais n'aurait rien fait.
  `i18n/*.json` est maintenant inclus.
- **Musique sans fils d'exécution.** Elle est composée dans un fil à part, mais l'export web est
  réglé sans fils (`variant/thread_support=false`), pour éviter les en-têtes COOP/COEP qu'exigent
  les fils dans un navigateur. Sans fils, elle est composée sur le fil principal une
  demi-seconde après le démarrage. L'image s'arrête un court instant, environ une seconde sur un
  ordinateur de bureau, plus sur une machine modeste.

**Particularités du navigateur :**

- La page doit être servie en HTTP : ouverte comme fichier (`file://`), elle ne charge pas.
- La progression, les réglages et les niveaux personnels sont gardés dans le stockage du
  navigateur (IndexedDB). Ils disparaissent si l'on efface les données du site, et ne passent
  pas d'un navigateur à l'autre.
- Pas de bouton Quitter ; Ctrl+Q et la confirmation de fermeture sont sans effet.
- Le navigateur n'autorise le son qu'après un premier clic ou une première touche.
- Le moteur WebAssembly pèse environ 40 Mo (`index.wasm`), et le jeu lui-même 0,4 Mo
  (`index.pck`). Le premier chargement prend donc quelques secondes ; un hébergeur qui compresse
  les fichiers (gzip, Brotli), comme itch.io, réduit beaucoup le wasm.
- « Actualiser en ligne » dans la galerie télécharge depuis raw.githubusercontent.com, qui
  autorise les requêtes d'autres sites (CORS).

**Pas encore vérifié** (aucun navigateur piloté ici) :

- le jeu dans Firefox, Chrome et Safari, son compris ;
- la durée réelle de l'arrêt dû à la musique ;
- les filmages en GIF et en vidéo, qui écrivent des fichiers dans le stockage du navigateur,
  où on ne peut pas facilement les récupérer ;
- l'ouverture du dossier des enregistrements et le lien « Proposer mon niveau… », qui
  dépendent de l'ouverture d'une page ou d'un dossier par le navigateur ;
- les performances du bac à sable avec beaucoup d'objets, le WebAssembly étant plus lent que la
  version native.

## Organisation

- `scripts/board.gd` : mécanique de jeu (disposition, simulation, victoire), sans interface.
- `scripts/main.gd`, `bin_item.gd`, `part_icon.gd` : interface ; `title_screen.gd` : écran titre ;
  `level_transition.gd` : passage d'un niveau à l'autre ; `chrono.gd` : chronomètre.
- `scripts/history.gd` : historique d'annulation, par niveau.
- `scripts/tutorial.gd` : bulles du tutoriel intégré ; les étapes sont dans les fichiers de niveau.
- `scripts/parts/` : une classe par pièce, dessinée par le code. `catalog.gd` les référence.
- `scripts/parts/rope_part.gd` : contrainte de longueur de la corde, enroulée sur les poulies et accrochée aux coins des obstacles (Godot n'a pas de joint poulie en 2D).
- `scripts/sfx.gd` : sons synthétisés par le code, sans fichier audio, dont les sons continus du
  tapis et du ventilateur ; `music.gd` : musique d'atelier, composée par le code elle aussi.
- `scripts/options_panel.gd` : fenêtre d'options ; `accessibility.gd` : couleurs de canaux
  adaptées et animations réduites ; `effects.gd` : particules décoratives (éclats, fumée, poussière, gouttes,
  étincelles) ; `darkness.gd` et
  `shaders/darkness.gdshader` : obscurité du grenier, percée par les lampes.
- `scripts/lang.gd` et `i18n/en.json` : traduction anglaise. Les textes sont écrits en français
  dans le code (`Lang.t("…")`) et dans les niveaux ; le fichier JSON associe à chacun sa
  traduction. `test_lang.gd` signale tout texte nouveau qui n'y figure pas.
- `scripts/wind.gd` : abri du vent, par lancer de rayons depuis l'amont.
- `gallery/index.cfg` : galerie de niveaux partagés (codes `BAB1:`) ; `scripts/gallery.gd` en décrit le
  format. Pour y ajouter un niveau proposé, coller son code dans une nouvelle section.
- `levels/` : les niveaux du jeu, un fichier texte par niveau (`07_contrepoids.cfg`), joués dans
  l'ordre des noms ; chacun indique son monde et sa solution. Chaque monde a sa dizaine (atelier
  01 à 19, cuisine 20, usine 30, espace 40, jardin 50, grenier 60), pour ajouter un niveau sans renuméroter les autres.
- `scripts/level_file.gd` : lecture et écriture de ces fichiers ; `level_data.gd` : mondes, bac à
  sable, éditeur et liste des niveaux.

## Tests

    export GODOT=/chemin/vers/Godot_v4.7.2-stable_linux.x86_64
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_levels.gd   # chaque niveau est faisable
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_ui.gd       # souris et clavier
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_rope.gd     # physique de la corde, sons
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_parts.gd    # pièces mécaniques
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_tutorial.gd # tutoriel intégré
    $GODOT --headless --path . --fixed-fps 120 -s tests/test_lang.gd     # traduction anglaise
    $GODOT --headless --path . --fixed-fps 120 -s tests/bench_perf.gd    # coût d'un pas de simulation
    $GODOT --path . -s tests/test_render.gd    # vignettes et cartes de niveau (affichage requis)
    SWEEP=spec.json $GODOT --headless --path . --fixed-fps 120 -s tests/sweep.gd   # aide à la conception
    CAPTURE_DIR=dossier $GODOT --path . -s tests/capture.gd              # captures (affichage requis)

### Performances

Mesures de `bench_perf.gd` (billes sur des étagères, millisecondes par pas ; le jeu en fait 120
par seconde, soit un budget de 8,3 ms) :

| Objets | Billes seules | Avec vent | Avec cordes |
| --- | --- | --- | --- |
| 25 | 0,5 | 1,7 | 1,8 |
| 100 | 2,4 | 6,8 | 6,8 |
| 200 | 4,6 | 14,1 | 14,9 |

Les niveaux du jeu comptent moins de 30 objets et restent loin du budget. Le vent (trois rayons
par corps et par pas) et les cordes (rayons pour s'accrocher aux coins) triplent le coût : au-delà
d'une centaine d'objets ventés ou reliés, le bac à sable peut ralentir. Les corps ne s'endorment
jamais, pour que la simulation reste identique d'un essai à l'autre ; le coût des billes seules en
découle, mais il reste modeste.

Pour ajouter un niveau : le construire dans l'éditeur du jeu lancé depuis les sources, le gagner
avec « Essayer », puis « Écrire (jeu)… » écrit son fichier dans `levels/` avec sa solution.
On peut aussi écrire le fichier à la main (format décrit en tête de `scripts/level_file.gd`, le
préfixe numérique fixe sa place) et chercher une large zone gagnante avec `sweep.gd`.
`test_levels.gd` vérifie ensuite que la solution gagne.

## Licence

Le code est distribué sous licence MIT : voir `LICENSE`.

class_name Bonus
## Objectifs bonus d'un niveau, en plus de l'objectif principal :
## « parts » : gagner avec au plus autant de pièces que la solution de référence ;
## « time » : gagner avant le temps de référence du niveau (`par_time`, en secondes) ;
## « all » : gagner en posant toutes les pièces du bac.

const KINDS: Array[String] = ["parts", "time", "all"]


static func par_parts(level: Dictionary) -> int:
	return level.get("par_parts", level.get("solution", []).size())


static func par_time(level: Dictionary) -> float:
	return level.get("par_time", 0.0)


static func inventory_size(level: Dictionary) -> int:
	var total := 0
	for count: int in level.get("inventory", {}).values():
		total += count
	return total


## Objectifs proposés : le temps seulement s'il est défini, « toutes les pièces » seulement si le
## bac contient plus de pièces qu'il n'en faut (sinon il double « peu de pièces »).
static func offered(level: Dictionary) -> Array[String]:
	var kinds: Array[String] = []
	if par_parts(level) > 0:
		kinds.append("parts")
	if par_time(level) > 0.0:
		kinds.append("time")
	if inventory_size(level) > par_parts(level):
		kinds.append("all")
	return kinds


static func describe(kind: String, level: Dictionary) -> String:
	match kind:
		"parts":
			return Lang.t("Économe : %d pièce(s) au plus") % par_parts(level)
		"time":
			return Lang.t("Rapide : en moins de %s s") % String.num(par_time(level), 1).replace(".", Lang.decimal_mark())
		"all":
			return Lang.t("Complet : toutes les pièces du bac")
	return kind


## Objectifs atteints par une victoire, d'après les pièces posées et la durée de la simulation.
static func earned(level: Dictionary, placed: int, seconds: float) -> Array[String]:
	var kinds: Array[String] = []
	for kind in offered(level):
		var ok := false
		match kind:
			"parts": ok = placed <= par_parts(level)
			"time": ok = seconds <= par_time(level)
			"all": ok = placed >= inventory_size(level)
		if ok:
			kinds.append(kind)
	return kinds

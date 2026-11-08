class_name Catalog
## Registre des pièces : noms affichés et fabrique.

const INFO := {
	"plank": {"label": "Planche", "desc": "Rampe fixe, à orienter."},
	"ball": {"label": "Bille", "desc": "Polyvalente, en acier : les aimants l'attirent."},
	"ball_bouncy": {"label": "Balle rebond", "desc": "Légère et très élastique."},
	"ball_heavy": {"label": "Boulet", "desc": "Lourd, ne rebondit pas. Les aimants l'attirent."},
	"crate": {"label": "Caisse", "desc": "Glisse plus qu'elle ne roule."},
	"domino": {"label": "Domino", "desc": "Se renverse et transmet le choc."},
	"seesaw": {"label": "Bascule", "desc": "Le côté haut chargé catapulte le côté bas."},
	"spring": {"label": "Ressort", "desc": "Renvoie tout à la même vitesse."},
	"plate": {"label": "Plaque", "desc": "Allume son canal au premier contact."},
	"trapdoor": {"label": "Trappe", "desc": "S'ouvre vers le bas quand son canal s'allume."},
	"door": {"label": "Porte", "desc": "S'ouvre quand son canal s'allume, se referme quand il s'éteint."},
	"scissors": {"label": "Ciseaux", "desc": "Coupent les cordes entre leurs lames quand leur canal s'allume."},
	"magnet": {"label": "Aimant", "desc": "Attire le boulet et la bille. Canal 0 : toujours actif."},
	"gear": {"label": "Engrenage", "desc": "Roue à bras, entraînée par les roues qui la touchent. R : bras."},
	"motor": {"label": "Moteur", "desc": "Fait tourner les engrenages qui le touchent. Miroir : sens."},
	"portal": {"label": "Portail", "desc": "Renvoie les objets par l'autre portail du même canal, à la même vitesse."},
	"water": {"label": "Bac d'eau", "desc": "Fait flotter les objets légers ; les lourds coulent lentement."},
	"suction": {"label": "Ventouse", "desc": "Retient ce qui touche sa coupelle. Canal 1 à 3 : lâche quand il s'allume."},
	"timer": {"label": "Minuterie", "desc": "Allume son canal un délai après le lancement (R : délai)."},
	"switch": {"label": "Interrupteur", "desc": "Chaque choc sur le levier allume ou éteint son canal."},
	"conveyor": {"label": "Tapis", "desc": "Canal 0 : toujours en marche."},
	"fan": {"label": "Ventilateur", "desc": "Souffle le léger. Canal 0 : toujours en marche."},
	"balloon": {"label": "Ballon", "desc": "Monte, éclate sur les pointes."},
	"spikes": {"label": "Pointes", "desc": "Font éclater les ballons."},
	"cannon": {"label": "Canon", "desc": "Tire une bille quand son canal s'allume."},
	"pulley": {"label": "Poulie", "desc": "Point de passage pour une corde."},
	"rope": {"label": "Corde", "desc": "Clique un objet, d'éventuelles poulies, puis un autre objet. R : mou."},
	"elastic": {"label": "Élastique", "desc": "Se pose comme une corde, mais s'étire et tire comme un ressort. R : tension."},
	"lamp": {"label": "Lampe", "desc": "S'allume avec son canal."},
	"basket": {"label": "Panier", "desc": "Objectif : y déposer un objet."},
}


## Liens posés en reliant deux pièces (corde, élastique) plutôt qu'en les glissant.
static func is_link(kind: String) -> bool:
	return kind == "rope" or kind == "elastic"


static func create(kind: String) -> Part:
	var part: Part
	match kind:
		"plank": part = PlankPart.new()
		"ball", "ball_bouncy", "ball_heavy": part = BallPart.new()
		"crate": part = CratePart.new()
		"domino": part = DominoPart.new()
		"seesaw": part = SeesawPart.new()
		"spring": part = SpringPart.new()
		"plate": part = PlatePart.new()
		"switch": part = SwitchPart.new()
		"timer": part = TimerPart.new()
		"gear", "motor": part = GearPart.new()
		"portal": part = PortalPart.new()
		"suction": part = SuctionPart.new()
		"water": part = WaterPart.new()
		"magnet": part = MagnetPart.new()
		"scissors": part = ScissorsPart.new()
		"trapdoor", "door": part = GatePart.new()
		"conveyor": part = ConveyorPart.new()
		"fan": part = FanPart.new()
		"balloon": part = BalloonPart.new()
		"spikes": part = SpikesPart.new()
		"cannon": part = CannonPart.new()
		"pulley": part = PulleyPart.new()
		"rope": part = RopePart.new()
		"elastic": part = ElasticPart.new()
		"lamp": part = LampPart.new()
		"basket": part = BasketPart.new()
		_:
			push_error("Pièce inconnue : %s" % kind)
			return null
	part.kind = kind
	return part

class_name Wind
## Abri du vent : le vent du niveau et celui des ventilateurs ne traversent plus les obstacles.
## On lance trois rayons parallèles au souffle, depuis l'amont jusqu'au corps, répartis sur sa
## largeur ; la part de rayons qui l'atteignent sans rien croiser donne la part de force reçue.
## Un objet à moitié caché derrière une planche ne reçoit donc qu'une partie du vent.

## Positions des rayons sur la largeur du corps, en fraction de son demi-encombrement.
const SAMPLES: Array[float] = [-0.6, 0.0, 0.6]


## Part du corps exposée au vent (0 à 1). `flow` : sens du souffle (unitaire) ; `upwind` : pour
## un point du corps, distance en amont d'où part le vent (0 ou moins : rien ne le précède).
## `exclude` : corps qui ne font pas écran (bords du plateau, ventilateur lui-même).
static func exposure(body: CollisionObject2D, flow: Vector2, upwind: Callable, exclude: Array[RID]) -> float:
	var space := body.get_world_2d().direct_space_state
	var across := flow.orthogonal()
	var half := half_width(body, across)
	var center := body.global_position
	var exposed := 0
	for sample in SAMPLES:
		var point := center + across * half * sample
		var reach: float = upwind.call(point)
		if reach <= 0.0:
			exposed += 1
			continue
		var query := PhysicsRayQueryParameters2D.create(point - flow * reach, point, Part.LAYER_WORLD, exclude)
		var hit := space.intersect_ray(query)
		if hit.is_empty() or hit.collider == body:
			exposed += 1
	return float(exposed) / SAMPLES.size()


## Demi-encombrement du corps dans une direction, d'après ses formes de collision.
static func half_width(body: CollisionObject2D, axis: Vector2) -> float:
	var half := 0.0
	for owner in body.get_shape_owners():
		var xf := body.global_transform * body.shape_owner_get_transform(owner)
		for i in body.shape_owner_get_shape_count(owner):
			var rect := body.shape_owner_get_shape(owner, i).get_rect()
			for corner: Vector2 in [rect.position, rect.end, Vector2(rect.position.x, rect.end.y),
					Vector2(rect.end.x, rect.position.y)]:
				half = maxf(half, absf((xf * corner - body.global_position).dot(axis)))
	return half

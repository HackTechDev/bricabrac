class_name History
extends RefCounted
## Historique d'annulation d'un niveau : une suite d'états complets de la disposition.

const LIMIT := 100

var present: Array

var _past: Array = []
var _future: Array = []


func _init(initial: Array) -> void:
	present = initial


## Enregistre un nouvel état ; renvoie false s'il ne change rien.
func record(state: Array) -> bool:
	if state == present:
		return false
	_past.append(present)
	if _past.size() > LIMIT:
		_past.pop_front()
	present = state
	_future.clear()
	return true


func can_undo() -> bool:
	return not _past.is_empty()


func can_redo() -> bool:
	return not _future.is_empty()


func undo() -> Array:
	_future.append(present)
	present = _past.pop_back()
	return present


func redo() -> Array:
	_past.append(present)
	present = _future.pop_back()
	return present

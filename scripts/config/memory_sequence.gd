class_name MemorySequence
extends Resource
## Orden en que se juegan las memorias. Se edita desde el Inspector en
## res://config/memory_sequence.tres: para reordenar o agregar una memoria basta con tocar la lista.
## Se guardan rutas (no PackedScene) para no cargar todas las escenas en memoria al arrancar.

## Escenas en orden de juego. La última es el final (el Despertar).
@export_file("*.tscn") var scene_paths: Array[String] = []


## Cantidad de escenas en la secuencia.
func size() -> int:
	return scene_paths.size()


## Ruta de la escena en esa posición, siempre como res:// (aunque esté guardada como uid://).
func get_path_at(index: int) -> String:
	return MemorySequence.normalize_path(scene_paths[index])


## Posición de una escena en la secuencia, o -1 si no está.
func index_of(scene_path: String) -> int:
	var target: String = MemorySequence.normalize_path(scene_path)
	for i: int in scene_paths.size():
		if get_path_at(i) == target:
			return i
	return -1


## Indica si esa posición es la última escena (el final del juego).
func is_last(index: int) -> bool:
	return index == scene_paths.size() - 1


## El Inspector puede guardar las rutas como uid://; las pasamos a res:// para poder compararlas.
static func normalize_path(path: String) -> String:
	if path.begins_with("uid://"):
		var id: int = ResourceUID.text_to_id(path)
		if ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
	return path

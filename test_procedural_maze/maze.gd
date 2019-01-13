tool
extends "res://addons/procedural_maze/maze_multimesh.gd"

func instanciate_objects(objects):
	var key_id = 0
	var key_color = Color(1.0, 0.0, 0.0)
	var last_key = null
	for o in objects:
		var object
		print(o)
		if o.type == "loot":
			if last_key != null or randi()%4 == 0:
				object = preload("res://test_procedural_maze/chest.tscn").instance()
			else:
				object = preload("res://test_procedural_maze/key.tscn").instance()
				object.set_color(key_color)
				last_key = object
		elif last_key != null and randi()%4 == 0 and o.type == "door":
			object = preload("res://test_procedural_maze/door.tscn").instance()
			object.set_color(key_color)
			last_key = null
			key_id += 1
			key_color.h += 0.1
		else:
			continue
		object.translation = corridor_width*Vector3(o.x, 0.0, o.y)
		object.rotation.y = MazeGenerator.DIRECTIONS[o.direction].a
		add_child(object) 
	if last_key != null:
		last_key.queue_free()

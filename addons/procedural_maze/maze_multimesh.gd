tool
extends "res://addons/procedural_maze/maze.gd"

export(Array) var wall_models = []
export(Array) var outer_wall_models = []
export(Mesh) var pillar_model = null

class MultiMeshBuilder:
	var mesh
	var instances = []
	
	static func sort(a, b):
		if a.position < b.position:
			return true
		return false
	
	func _init(m):
		mesh = m
	
	func add(position, rotation):
		instances.append({ position=position, rotation=rotation })
	
	func finalize(parent, remove_duplicates = false):
		var multi_mesh = MultiMesh.new()
		if remove_duplicates:
			instances.sort_custom(self, "sort")
			var new_instances = []
			var last = null
			for i in instances:
				if last != i.position:
					new_instances.append(i)
				last = i.position
			instances = new_instances
		multi_mesh.mesh = mesh
		multi_mesh.color_format = MultiMesh.COLOR_NONE
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.instance_count = instances.size()
		for i in range(instances.size()):
			var instance = instances[i]
			var basis = Basis().rotated(Vector3(0, 1, 0), instance.rotation)
			multi_mesh.set_instance_transform(i, Transform(basis, instance.position))
		var multi_mesh_instance = MultiMeshInstance.new()
		multi_mesh_instance.multimesh = multi_mesh
		parent.add_child(multi_mesh_instance)

func generate_walls_mesh(generator, builder):
	# Create multi_mesh
	var inner_walls = []
	var outer_walls = []
	var pillars = null
	if pillar_model != null:
		pillars = MultiMeshBuilder.new(pillar_model)
	for m in wall_models:
		inner_walls.append(MultiMeshBuilder.new(m))
	for m in outer_wall_models:
		outer_walls.append(MultiMeshBuilder.new(m))
	if outer_walls.empty():
		outer_walls = inner_walls
	if inner_walls.empty():
		return
	for i in range(0, generator.walls_x.size(), 3):
		var y = generator.walls_x[i]
		var x1 = generator.walls_x[i+1]
		var x2 = generator.walls_x[i+2]
		for x in range(x1, x2+1):
			var rnd = randi()
			if y == 0:
				outer_walls[rnd%outer_walls.size()].add(corridor_width*(Vector3(x, 0, y-0.5)), PI)
			elif y == size_y:
				outer_walls[rnd%outer_walls.size()].add(corridor_width*(Vector3(x, 0, y-0.5)), 0)
			else:
				inner_walls[rnd%inner_walls.size()].add(corridor_width*(Vector3(x, 0, y-0.5)), ((rnd >> 8)&1)*PI)
		if pillars != null and y > 0 and y < size_y:
			if x1 > 0:
				pillars.add(corridor_width*(Vector3(x1-0.5, 0, y-0.5)), 0)
			if x2 < size_x-1:
				pillars.add(corridor_width*(Vector3(x2+0.5, 0, y-0.5)), 0)
	for i in range(0, generator.walls_y.size(), 3):
		var x = generator.walls_y[i]
		var y1 = generator.walls_y[i+1]
		var y2 = generator.walls_y[i+2]
		for y in range(y1, y2+1):
			var rnd = randi()
			if x == 0:
				outer_walls[rnd%outer_walls.size()].add(corridor_width*(Vector3(x-0.5, 0, y)), -0.5*PI)
			elif x == size_x:
				outer_walls[rnd%outer_walls.size()].add(corridor_width*(Vector3(x-0.5, 0, y)), 0.5*PI)
			else:
				inner_walls[rnd%inner_walls.size()].add(corridor_width*(Vector3(x-0.5, 0, y)), (0.5+((rnd >> 8)&1))*PI)
		if pillars != null and x > 0 and x < size_x:
			if y1 > 0:
				pillars.add(corridor_width*(Vector3(x-0.5, 0, y1-0.5)), 0)
			if y2 < size_y-1:
				pillars.add(corridor_width*(Vector3(x-0.5, 0, y2+0.5)), 0)
	for i in inner_walls:
		i.finalize(self)
	for i in outer_walls:
		i.finalize(self)
	if pillars != null:
		pillars.finalize(self, true)

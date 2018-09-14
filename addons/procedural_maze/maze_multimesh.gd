tool
extends "res://addons/procedural_maze/maze.gd"

export(Array) var wall_models = []

class MultiMeshBuilder:
	var mesh
	var instances = []
	
	func _init(m):
		mesh = m
	
	func add(position, rotation):
		instances.append({ position=position, rotation=rotation })
	
	func finalize(parent):
		var multi_mesh = MultiMesh.new()
		multi_mesh.mesh = mesh
		multi_mesh.color_format = MultiMesh.COLOR_NONE
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.instance_count = instances.size()
		print(str(multi_mesh.instance_count)+" instances")
		for i in range(instances.size()):
			var instance = instances[i]
			var basis = Basis().rotated(Vector3(0, 1, 0), instance.rotation)
			multi_mesh.set_instance_transform(i, Transform(basis, instance.position))
		var multi_mesh_instance = MultiMeshInstance.new()
		multi_mesh_instance.multimesh = multi_mesh
		parent.add_child(multi_mesh_instance)

func generate_walls_mesh(generator, builder):
	# Create multi_mesh
	var outer_walls = []
	var inner_walls = []
	var pillars = MultiMeshBuilder.new(load("res://test_procedural_maze/models/pillar.tres"))
	for m in wall_models:
		print(m)
		inner_walls.append(MultiMeshBuilder.new(m))
	for i in range(0, generator.walls_x.size(), 3):
		var y = generator.walls_x[i]
		var x1 = generator.walls_x[i+1]
		var x2 = generator.walls_x[i+2]
		for x in range(x1, x2+1):
			var model = randi()%inner_walls.size()
			inner_walls[model].add(corridor_width*(Vector3(x, 0, y-0.5)), 0)
		pillars.add(corridor_width*(Vector3(x1-0.5, 0, y-0.5)), 0)
		pillars.add(corridor_width*(Vector3(x2+0.5, 0, y-0.5)), 0)
	for i in range(0, generator.walls_y.size(), 3):
		var x = generator.walls_y[i]
		var y1 = generator.walls_y[i+1]
		var y2 = generator.walls_y[i+2]
		for y in range(y1, y2+1):
			var model = randi()%inner_walls.size()
			inner_walls[model].add(corridor_width*(Vector3(x-0.5, 0, y)), 0.5*PI)
		pillars.add(corridor_width*(Vector3(x-0.5, 0, y1-0.5)), 0)
		pillars.add(corridor_width*(Vector3(x-0.5, 0, y2+0.5)), 0)
	for i in inner_walls:
		i.finalize(self)
	pillars.finalize(self)

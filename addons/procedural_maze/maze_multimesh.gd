tool
extends "res://addons/procedural_maze/maze.gd"

export(Array) var wall_models = []

func generate_walls_mesh(generator, builder):
	# Create multi_mesh
	var multi_mesh = []
	var count = PoolIntArray()
	var index = PoolIntArray()
	for i in range(4):
		multi_mesh.append(MultiMesh.new())
		count.append(0)
		index.append(0)
	seed(0)
	var all_pillars = []
	for i in range(0, generator.walls_x.size(), 3):
		var y = generator.walls_x[i]
		var x1 = generator.walls_x[i+1]
		var x2 = generator.walls_x[i+2]
		for j in range(x1, x2+1):
			var model = randi()%3
			count[model] += 1
		all_pillars.append(Vector2(x1, y))
		all_pillars.append(Vector2(x2+1, y))
	for i in range(0, generator.walls_y.size(), 3):
		var x = generator.walls_y[i]
		var y1 = generator.walls_y[i+1]
		var y2 = generator.walls_y[i+2]
		for j in range(y1, y2+1):
			var model = randi()%3
			count[model] += 1
		all_pillars.append(Vector2(x, y1))
		all_pillars.append(Vector2(x, y2+1))
	for i in range(3):
		multi_mesh[i].color_format = MultiMesh.COLOR_NONE
		multi_mesh[i].transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh[i].instance_count = count[i]
		multi_mesh[i].mesh = load("res://test_procedural_maze/models/wall"+str(i+1)+".tres")
	print(all_pillars.size())
	all_pillars.sort()
	var pillars = PoolVector2Array()
	var last = null
	while !all_pillars.empty():
		var element = all_pillars.pop_back()
		if element != last:
			pillars.append(element)
		last = element
	count[3] = pillars.size()
	print(count[3])
	multi_mesh[3].color_format = MultiMesh.COLOR_NONE
	multi_mesh[3].transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh[3].instance_count = count[3]
	multi_mesh[3].mesh = load("res://test_procedural_maze/models/pillar.tres")
	seed(0)
	var basis = Basis()
	for i in range(0, generator.walls_x.size(), 3):
		var y = generator.walls_x[i]
		var x1 = generator.walls_x[i+1]
		var x2 = generator.walls_x[i+2]
		for x in range(x1, x2+1):
			var model = randi()%3
			multi_mesh[model].set_instance_transform(index[model], Transform(basis, corridor_width*(Vector3(x, 0, y-0.5))))
			index[model] += 1
	basis = basis.rotated(Vector3(0, 1, 0), 0.5*PI)
	for i in range(0, generator.walls_y.size(), 3):
		var x = generator.walls_y[i]
		var y1 = generator.walls_y[i+1]
		var y2 = generator.walls_y[i+2]
		for y in range(y1, y2+1):
			var model = randi()%3
			multi_mesh[model].set_instance_transform(index[model], Transform(basis, corridor_width*(Vector3(x-0.5, 0, y))))
			index[model] += 1
	for i in pillars:
		multi_mesh[3].set_instance_transform(index[3], Transform(basis, corridor_width*(Vector3(i.x-0.5, 0, i.y-0.5))))
		index[3] += 1
	for i in range(4):
		var mesh = MultiMeshInstance.new()
		mesh.multimesh = multi_mesh[i]
		add_child(mesh)

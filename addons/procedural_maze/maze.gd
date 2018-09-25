tool
extends StaticBody

export(int, 2, 100) var size_x = 5 setget set_size_x
export(int, 2, 100) var size_y = 5 setget set_size_y
export(float) var corridor_width = 4.0
export(float) var wall_width = 0.1
export(float) var height = 2.6
export(int) var random_seed = 0 setget set_random_seed
export(Material) var wall_material
export(Material) var floor_material
export(Material) var ceiling_material

const MazeGenerator = preload("res://addons/procedural_maze/maze_generator.gd")

func _ready():
	generate()

func set_size_x(s):
	size_x = s
	if Engine.editor_hint:
		generate()

func set_size_y(s):
	size_y = s
	if Engine.editor_hint:
		generate()

func set_random_seed(s):
	random_seed = s
	if Engine.editor_hint:
		generate()

func generate():
	# Remove existing walls
	var config = null
	for c in get_children():
		if c.name != "Config":
			c.queue_free()
		else:
			config = get_node("Config")
#	print("Removing %d shape owners" % get_shape_owners().size())
#	for o in get_shape_owners():
#		shape_owner_clear_shapes(o)
#		remove_shape_owner(o)
	var generator = MazeGenerator.new()
	generator.initialize(size_x, size_y, corridor_width, wall_width, height)
	if config != null:
		for c in get_node("Config").get_children():
			if c is CollisionShape:
				var shape = c.shape
				if shape != null and shape is BoxShape:
					var corner1 = c.transform.xform(-shape.extents)
					var corner2 = c.transform.xform(shape.extents)
					var rect = Rect2(Vector2(corner1.x, corner1.z)/corridor_width, Vector2(corner2.x-corner1.x, corner2.z-corner1.z)/corridor_width)
					generator.open(rect)
	var time = OS.get_unix_time()
	var objects = generator.generate(random_seed)
	generator.generate_walls()
	print("Generated maze in %d seconds" % (OS.get_unix_time() - time))
	time = OS.get_unix_time()
	generate_collision_shapes(generator)
	print("Generated collision shapes in %d seconds" % (OS.get_unix_time() - time))
	time = OS.get_unix_time()
	generate_meshes(generator)
	print("Generated meshes in %d seconds" % (OS.get_unix_time() - time))
	instanciate_objects(objects)

func instanciate_objects(objects):
	pass

func generate_walls(generator, builder):
	for i in range(0, generator.walls_x.size(), 3):
		var y = generator.walls_x[i]
		var x1 = generator.walls_x[i+1]
		var x2 = generator.walls_x[i+2]
		builder.create_wall(corridor_width*(Vector2(x1-0.5, y-0.5))-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(x2+0.5, y-0.5))+0.5*wall_width*Vector2(1, 1), height)
	for i in range(0, generator.walls_y.size(), 3):
		var x = generator.walls_y[i]
		var y1 = generator.walls_y[i+1]
		var y2 = generator.walls_y[i+2]
		builder.create_wall(corridor_width*(Vector2(x-0.5, y1-0.5))-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(x-0.5, y2+0.5))+0.5*wall_width*Vector2(1, 1), height)

class CollisionBuilder:
	extends Node
	
	var collision_object
	var collision_shape
	var shapes = 0
	
	func _init(o):
		collision_object = o
		collision_shape = CollisionShape.new()
		collision_object.add_child(collision_shape)
	
	func add_shape(center, extent, low, height):
		if shapes >= 50:
			collision_shape = CollisionShape.new()
			collision_object.add_child(collision_shape)
			shapes = 0
		else:
			shapes += 1
		var shape_owner = collision_object.create_shape_owner(collision_shape)
		var shape = BoxShape.new()
		shape.extents = Vector3(extent.x, 0.5*height, extent.y)
		var transform = Transform().translated(Vector3(center.x, low+0.5*height, center.y))
		collision_object.shape_owner_set_transform(shape_owner, transform)
		collision_object.shape_owner_add_shape(shape_owner, shape)
	
	func create_wall(from, to, height):
		var center = 0.5*(from+to)
		var extent = to-center
		add_shape(center, extent, 0, height)

func generate_collision_shapes(generator):
	if Engine.editor_hint:
		return
	var builder = CollisionBuilder.new(self)
	# Generate floor
	builder.add_shape(Vector2(0.5*corridor_width*size_x, 0.5*corridor_width*size_y), Vector2(0.5*corridor_width*(size_x+1), 0.5*corridor_width*(size_y+1)), -1, 1)
	# Generate walls
	generate_walls(generator, builder)

class MeshBuilder:
	extends Node
	
	var vertices
	var uvs
	var normals
	var tangents
	
	func _init():
		clear()
	
	func clear():
		vertices = PoolVector3Array()
		uvs = PoolVector2Array()
		normals = PoolVector3Array()
		tangents = PoolRealArray()
	
	func add_point(vertex, uv, normal, tangent):
		vertices.append(vertex)
		uvs.append(uv)
		normals.append(normal)
		tangents.append(tangent[0])
		tangents.append(tangent[1])
		tangents.append(tangent[2])
		tangents.append(tangent[3])
	
	func create_vertical_rect(from, to, height):
		var uv_from = from.y
		var uv_to = to.y
		if abs(from.x-to.x) > abs(from.y-to.y):
			uv_from = from.x
			uv_to = to.x
		var normal = Vector3(from.y-to.y, 0, to.x-from.x).normalized()
		var tangent = [normal.z, 0, -normal.x, 1]
		add_point(Vector3(from.x, 0, from.y), Vector2(uv_from, 0), normal, tangent)
		add_point(Vector3(from.x, height, from.y), Vector2(uv_from, height), normal, tangent)
		add_point(Vector3(to.x, 0, to.y), Vector2(uv_to, 0), normal, tangent)
		add_point(Vector3(from.x, height, from.y), Vector2(uv_from, height), normal, tangent)
		add_point(Vector3(to.x, height, to.y), Vector2(uv_to, height), normal, tangent)
		add_point(Vector3(to.x, 0, to.y), Vector2(uv_to, 0), normal, tangent)
	
	func create_wall(from, to, height):
		create_vertical_rect(Vector2(from.x, from.y), Vector2(from.x, to.y), height)
		create_vertical_rect(Vector2(from.x, to.y), Vector2(to.x, to.y), height)
		create_vertical_rect(Vector2(to.x, to.y), Vector2(to.x, from.y), height)
		create_vertical_rect(Vector2(to.x, from.y), Vector2(from.x, from.y), height)

func generate_floor_mesh(builder):
	# Generate mesh
	if floor_material != null:
		builder.clear()
		var p1 = -(corridor_width+wall_width)*0.5*Vector2(1, 1)
		var p2 = corridor_width*Vector2(size_x-1, size_y-1)-p1
		var normal = Vector3(0, 1, 0)
		var tangent = [ 1, 0, 0, 1 ]
		builder.add_point(Vector3(p1.x, 0, p1.y), Vector2(p1.x, p1.y), normal, tangent)
		builder.add_point(Vector3(p2.x, 0, p1.y), Vector2(p2.x, p1.y), normal, tangent)
		builder.add_point(Vector3(p1.x, 0, p2.y), Vector2(p1.x, p2.y), normal, tangent)
		builder.add_point(Vector3(p2.x, 0, p2.y), Vector2(p2.x, p2.y), normal, tangent)
		var mesh = MeshInstance.new()
		mesh.name = "floor"
		mesh.mesh = ArrayMesh.new()
		mesh.mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLE_STRIP, [ builder.vertices, builder.normals, builder.tangents, null, builder.uvs, null, null, null, null ])
		mesh.mesh.surface_set_material(0, floor_material)
		add_child(mesh)

func generate_ceiling_mesh(builder):
	if ceiling_material != null:
		builder.clear()
		var p1 = -(corridor_width+wall_width)*0.5*Vector2(1, 1)
		var p2 = corridor_width*Vector2(size_x-1, size_y-1)-p1
		var normal = Vector3(0, -1, 0)
		var tangent = [ 1, 0, 0, 1 ]
		builder.add_point(Vector3(p1.x, height, p1.y), Vector2(p1.x, p1.y), normal, tangent)
		builder.add_point(Vector3(p1.x, height, p2.y), Vector2(p1.x, p2.y), normal, tangent)
		builder.add_point(Vector3(p2.x, height, p1.y), Vector2(p2.x, p1.y), normal, tangent)
		builder.add_point(Vector3(p2.x, height, p2.y), Vector2(p2.x, p2.y), normal, tangent)
		var mesh = MeshInstance.new()
		mesh.name = "floor"
		mesh.mesh = ArrayMesh.new()
		mesh.mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLE_STRIP, [ builder.vertices, builder.normals, builder.tangents, null, builder.uvs, null, null, null, null ])
		mesh.mesh.surface_set_material(0, ceiling_material)
		add_child(mesh)

func generate_walls_mesh(generator, builder):
	if wall_material != null:
		builder.clear()
		generate_walls(generator, builder)
		var mesh = MeshInstance.new()
		mesh.name = "walls"
		mesh.mesh = ArrayMesh.new()
		mesh.mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, [ builder.vertices, builder.normals, builder.tangents, null, builder.uvs, null, null, null, null ])
		mesh.mesh.surface_set_material(0, wall_material)
		add_child(mesh)

func generate_meshes(generator):
	var builder = MeshBuilder.new()
	generate_floor_mesh(builder)
	generate_ceiling_mesh(builder)
	generate_walls_mesh(generator, builder)


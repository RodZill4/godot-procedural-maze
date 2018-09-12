tool
extends Node

var size_x
var size_y
var corridor_width
var wall_width
var height

var cells = []
var loot = []

const DIRECTIONS = [ { x=-1, y=0, r=1 }, { x=0, y=-1, r=0 }, { x=1, y=0, r=1 }, { x=0, y=1, r=0 } ]
const DIRECTION_LEFT  = 0
const DIRECTION_UP    = 1
const DIRECTION_RIGHT = 2
const DIRECTION_DOWN  = 3
const MASK_VISITED    = 16

func initialize(_size_x, _size_y, _corridor_width, _wall_width, _height):
	size_x = _size_x
	size_y = _size_y
	corridor_width = _corridor_width
	wall_width = _wall_width
	height = _height
	cells = []
	for x in range(size_x):
		var line = []
		for y in range(size_y):
			line.append(0)
		cells.append(line)
	loot = []

func open(rect):
	var min_x = max(0, min(size_x-1, rect.position.x-1))
	var max_x = max(0, min(size_x-1, rect.end.x+1))
	var min_y = max(0, min(size_y-1, rect.position.y-1))
	var max_y = max(0, min(size_y-1, rect.end.y+1))
	for x in range(min_x, max_x+1):
		for y in range(min_y, max_y+1):
			if rect.has_point(Vector2(x, y)):
				cells[x][y] |= MASK_VISITED
			for d in range(4):
				if rect.has_point(Vector2(x, y)+0.5*Vector2(DIRECTIONS[d].x, DIRECTIONS[d].y)):
					cells[x][y] |= (1 << d)

func generate(random_seed):
	var time = OS.get_unix_time()
	seed(random_seed)
	# Generate maze
	var current = { x=0, y=0 }
	var remaining = size_x*size_y-1
	var stack = []
	cells[current.x][current.y] |= MASK_VISITED
	var backtracking = false
	while remaining > 0:
		var choices = []
		for d in range(4):
			var x = current.x+DIRECTIONS[d].x
			var y = current.y+DIRECTIONS[d].y
			if x >= 0 && y >= 0 && x < size_x && y < size_y && (cells[x][y] & MASK_VISITED) == 0:
				choices.append(d)
		if choices.empty():
			if !backtracking:
				loot.append( { x=current.x, y=current.y, loot="loot1" } )
			if stack.empty():
				break
			current = stack.pop_back()
			backtracking = true
		else:
			if backtracking:
				pass
			var d = choices[randi() % choices.size()]
			stack.append(current.duplicate())
			cells[current.x][current.y] |= (1 << d)
			current.x += DIRECTIONS[d].x
			current.y += DIRECTIONS[d].y
			cells[current.x][current.y] |= (1 << ((d + 2) % 4)) | MASK_VISITED
			remaining -= 1
			backtracking = false
	# Add ending loot if any
	loot.append( { x=current.x, y=current.y, loot="loot3" } )
	return loot

class MeshBuilder:
	extends Node
	
	var collision_object
	var collision_shape
	var vertices
	var uvs
	var normals
	var tangents
	
	func _init(o):
		collision_object = o
		collision_shape = CollisionShape.new()
		collision_object.add_child(collision_shape)
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

	func create_collision_shape_old(center, extent, height):
		if Engine.editor_hint:
			return
		var shape = CollisionShape.new()
		shape.translation = Vector3(center.x, 0.5*height, center.y)
		shape.shape = BoxShape.new()
		shape.shape.extents = Vector3(extent.x, 0.5*height, extent.y)
		collision_object.add_child(shape)

	func create_collision_shape(center, extent, height):
		if Engine.editor_hint:
			return
		var shape_owner = collision_object.create_shape_owner(collision_shape)
		var shape = BoxShape.new()
		shape.extents = Vector3(extent.x, 0.5*height, extent.y)
		var transform = Transform().translated(Vector3(center.x, 0.5*height, center.y))
		collision_object.shape_owner_set_transform(shape_owner, transform)
		collision_object.shape_owner_add_shape(shape_owner, shape)

func generate_floor(maze, material):
	# Generate collision shape
	var shape = CollisionShape.new()
	shape.translation = Vector3(0.5*corridor_width*size_x, -0.5, 0.5*corridor_width*size_y)
	shape.shape = BoxShape.new()
	shape.shape.extents = Vector3(0.5*corridor_width*(size_x+1), 0.5, 0.5*corridor_width*(size_y+1))
	maze.add_child(shape)
	# Generate mesh
	if material != null:
		var context = MeshBuilder.new(maze)
		print(context.vertices)
		var p1 = -(corridor_width+wall_width)*0.5*Vector2(1, 1)
		var p2 = corridor_width*Vector2(size_x-1, size_y-1)-p1
		var normal = Vector3(0, 1, 0)
		var tangent = [ 1, 0, 0, 1 ]
		context.add_point(Vector3(p1.x, 0, p1.y), Vector2(p1.x, p1.y), normal, tangent)
		context.add_point(Vector3(p2.x, 0, p1.y), Vector2(p2.x, p1.y), normal, tangent)
		context.add_point(Vector3(p1.x, 0, p2.y), Vector2(p1.x, p2.y), normal, tangent)
		context.add_point(Vector3(p2.x, 0, p2.y), Vector2(p2.x, p2.y), normal, tangent)
		var mesh = MeshInstance.new()
		mesh.name = "floor"
		mesh.mesh = ArrayMesh.new()
		mesh.mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLE_STRIP, [ context.vertices, context.normals, context.tangents, null, context.uvs, null, null, null, null ])
		mesh.mesh.surface_set_material(0, material)
		maze.add_child(mesh)

func generate_walls(maze, material):
	if material == null:
		material = SpatialMaterial.new()
	var context = MeshBuilder.new(maze)
	generate_walls_along_x(maze, 0, DIRECTION_UP, context)
	for y in range(size_y):
		generate_walls_along_x(maze, y, DIRECTION_DOWN, context)
	generate_walls_along_y(maze, 0, DIRECTION_LEFT, context)
	for x in range(size_x):
		generate_walls_along_y(maze, x, DIRECTION_RIGHT, context)
	var mesh = MeshInstance.new()
	mesh.name = "walls"
	mesh.mesh = ArrayMesh.new()
	mesh.mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, [ context.vertices, context.normals, context.tangents, null, context.uvs, null, null, null, null ])
	mesh.mesh.surface_set_material(0, material)
	maze.add_child(mesh)

func create_vertical_rect(from, to, context):
	var uv_from = from.y
	var uv_to = to.y
	if abs(from.x-to.x) > abs(from.y-to.y):
		uv_from = from.x
		uv_to = to.x
	var normal = Vector3(from.y-to.y, 0, to.x-from.x).normalized()
	var tangent = [normal.z, 0, -normal.x, 1]
	context.add_point(Vector3(from.x, 0, from.y), Vector2(uv_from, 0), normal, tangent)
	context.add_point(Vector3(from.x, height, from.y), Vector2(uv_from, height), normal, tangent)
	context.add_point(Vector3(to.x, 0, to.y), Vector2(uv_to, 0), normal, tangent)
	context.add_point(Vector3(from.x, height, from.y), Vector2(uv_from, height), normal, tangent)
	context.add_point(Vector3(to.x, height, to.y), Vector2(uv_to, height), normal, tangent)
	context.add_point(Vector3(to.x, 0, to.y), Vector2(uv_to, 0), normal, tangent)

func create_wall(maze, from, to, context):
	create_vertical_rect(Vector2(from.x, from.y), Vector2(from.x, to.y), context)
	create_vertical_rect(Vector2(from.x, to.y), Vector2(to.x, to.y), context)
	create_vertical_rect(Vector2(to.x, to.y), Vector2(to.x, from.y), context)
	create_vertical_rect(Vector2(to.x, from.y), Vector2(from.x, from.y), context)
	var center = 0.5*(from+to)
	var extent = to-center
	context.create_collision_shape(center, extent, height)

func generate_walls_along_x(maze, y, d, context):
	var mask = (1 << d)
	var offset = 0.5*Vector2(DIRECTIONS[d].x, DIRECTIONS[d].y)
	var wall_begin = null
	for x in range(size_x):
		if wall_begin == null && (cells[x][y] & mask) == 0:
			wall_begin = x
		elif wall_begin != null && (cells[x][y] & mask) != 0:
			create_wall(maze, corridor_width*(Vector2(wall_begin-0.5, y)+offset)-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(x-0.5, y)+offset)+0.5*wall_width*Vector2(1, 1), context)
			wall_begin = null
	if wall_begin != null:
		create_wall(maze, corridor_width*(Vector2(wall_begin-0.5, y)+offset)-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(size_x-0.5, y)+offset)+0.5*wall_width*Vector2(1, 1), context)

func generate_walls_along_y(maze, x, d, context):
	var mask = (1 << d)
	var offset = 0.5*Vector2(DIRECTIONS[d].x, DIRECTIONS[d].y)
	var wall_begin = null
	for y in range(size_y):
		if wall_begin == null && (cells[x][y] & mask) == 0:
			wall_begin = y
		elif wall_begin != null && (cells[x][y] & mask) != 0:
			create_wall(maze, corridor_width*(Vector2(x, wall_begin-0.5)+offset)-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(x, y-0.5)+offset)+0.5*wall_width*Vector2(1, 1), context)
			wall_begin = null
	if wall_begin != null:
		create_wall(maze, corridor_width*(Vector2(x, wall_begin-0.5)+offset)-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(x, size_y-0.5)+offset)+0.5*wall_width*Vector2(1, 1), context)

func generate_ceiling(maze, material):
	if material != null:
		var context = MeshBuilder.new(maze)
		var p1 = -(corridor_width+wall_width)*0.5*Vector2(1, 1)
		var p2 = corridor_width*Vector2(size_x-1, size_y-1)-p1
		var normal = Vector3(0, -1, 0)
		var tangent = [ 1, 0, 0, 1 ]
		context.add_point(Vector3(p1.x, height, p1.y), Vector2(p1.x, p1.y), normal, tangent)
		context.add_point(Vector3(p1.x, height, p2.y), Vector2(p1.x, p2.y), normal, tangent)
		context.add_point(Vector3(p2.x, height, p1.y), Vector2(p2.x, p1.y), normal, tangent)
		context.add_point(Vector3(p2.x, height, p2.y), Vector2(p2.x, p2.y), normal, tangent)
		var mesh = MeshInstance.new()
		mesh.name = "floor"
		mesh.mesh = ArrayMesh.new()
		mesh.mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLE_STRIP, [ context.vertices, context.normals, context.tangents, null, context.uvs, null, null, null, null ])
		mesh.mesh.surface_set_material(0, material)
		maze.add_child(mesh)

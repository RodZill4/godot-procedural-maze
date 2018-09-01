tool
extends StaticBody

export(int, 2, 25) var size_x = 5 setget set_size_x
export(int, 2, 25) var size_y = 5 setget set_size_y
export(float) var corridor_width = 4.0
export(float) var wall_width = 0.1
export(float) var height = 2.6
export(int) var random_seed = 0 setget set_random_seed
export(Material) var wall_material
export(Material) var floor_material
export(Material) var ceiling_material

export(PackedScene) var loot1
export(PackedScene) var loot2
export(PackedScene) var loot3

export(PackedScene) var light

export(PackedScene) var key
export(PackedScene) var door

var cells = []

const DIRECTIONS = [ { x=-1, y=0, r=1 }, { x=0, y=-1, r=0 }, { x=1, y=0, r=1 }, { x=0, y=1, r=0 } ]
const DIRECTION_LEFT  = 0
const DIRECTION_UP    = 1
const DIRECTION_RIGHT = 2
const DIRECTION_DOWN  = 3
const MASK_VISITED    = 16

func _ready():
	generate()

func set_size_x(s):
	size_x = s
	generate()

func set_size_y(s):
	size_y = s
	generate()

func set_random_seed(s):
	random_seed = s
	generate()

func generate():
	seed(random_seed)
	# Remove existing walls
	for c in get_children():
		if c.name != "Config":
			c.queue_free()
	# Initialize grid
	cells = []
	for x in range(size_x):
		var line = []
		for y in range(size_y):
			line.append(0)
		cells.append(line)
	# Generate maze
	var current = { x=0, y=0 }
	var remaining = size_x*size_y-1
	var stack = []
	cells[current.x][current.y] |= 1 | MASK_VISITED
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
				if loot1 != null:
					var object = loot1.instance()
					object.translation = corridor_width*Vector3(current.x, 0, current.y)
					add_child(object)
			current = stack.pop_back()
			backtracking = true
		else:
			if backtracking:
				if light != null:
					print("adding light")
					var object = light.instance()
					object.translation = corridor_width*Vector3(current.x, 0, current.y)
					add_child(object)
			var d = choices[randi() % choices.size()]
			stack.append(current.duplicate())
			cells[current.x][current.y] |= (1 << d)
			current.x += DIRECTIONS[d].x
			current.y += DIRECTIONS[d].y
			cells[current.x][current.y] |= (1 << ((d + 2) % 4)) | MASK_VISITED
			remaining -= 1
			backtracking = false
	# Add ending loot if any
	if loot3 != null:
		var object = loot3.instance()
		object.translation = corridor_width*Vector3(current.x, 0, current.y)
		add_child(object)
	# Vars for generation
	var shape
	var context
	# Generate floor
	shape = CollisionShape.new()
	shape.translation = Vector3(0.5*corridor_width*size_x, -0.5, 0.5*corridor_width*size_y)
	shape.shape = BoxShape.new()
	shape.shape.extents = Vector3(0.5*corridor_width*(size_x+1), 0.5, 0.5*corridor_width*(size_y+1))
	add_child(shape)
	if floor_material != null:
		context = { vertices=[ ], uvs=[ ], normals=[ ], tangents=[ ] }
		var p1 = -(corridor_width+wall_width)*0.5*Vector2(1, 1)
		var p2 = corridor_width*Vector2(size_x-1, size_y-1)-p1
		var normal = Vector3(0, 1, 0)
		var tangent = [ 1, 0, 0, 1 ]
		add_point(context, Vector3(p1.x, 0, p1.y), Vector2(p1.x, p1.y), normal, tangent)
		add_point(context, Vector3(p2.x, 0, p1.y), Vector2(p2.x, p1.y), normal, tangent)
		add_point(context, Vector3(p1.x, 0, p2.y), Vector2(p1.x, p2.y), normal, tangent)
		add_point(context, Vector3(p2.x, 0, p2.y), Vector2(p2.x, p2.y), normal, tangent)
		var floor_mesh = MeshInstance.new()
		floor_mesh.name = "floor"
		floor_mesh.mesh = ArrayMesh.new()
		floor_mesh.mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLE_STRIP, [ PoolVector3Array(context.vertices), PoolVector3Array(context.normals), PoolRealArray(context.tangents), null, PoolVector2Array(context.uvs), null, null, null, null ])
		floor_mesh.mesh.surface_set_material(0, floor_material)
		add_child(floor_mesh)
	# Generate floor
	var material = wall_material
	if material == null:
		material = SpatialMaterial.new()
	context = { vertices=[ ], uvs=[ ], normals=[ ], tangents=[ ] }
	generate_walls_along_x(0, DIRECTION_UP, context)
	for y in range(size_y):
		generate_walls_along_x(y, DIRECTION_DOWN, context)
	generate_walls_along_y(0, DIRECTION_LEFT, context)
	for x in range(size_x):
		generate_walls_along_y(x, DIRECTION_RIGHT, context)
	var walls_mesh = MeshInstance.new()
	walls_mesh.name = "walls"
	walls_mesh.mesh = ArrayMesh.new()
	walls_mesh.mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, [ PoolVector3Array(context.vertices), PoolVector3Array(context.normals), PoolRealArray(context.tangents), null, PoolVector2Array(context.uvs), null, null, null, null ])
	walls_mesh.mesh.surface_set_material(0, material)
	add_child(walls_mesh)
	if ceiling_material != null:
		context = { vertices=[ ], uvs=[ ], normals=[ ], tangents=[ ] }
		var p1 = -(corridor_width+wall_width)*0.5*Vector2(1, 1)
		var p2 = corridor_width*Vector2(size_x-1, size_y-1)-p1
		var normal = Vector3(0, -1, 0)
		var tangent = [ 1, 0, 0, 1 ]
		add_point(context, Vector3(p1.x, height, p1.y), Vector2(p1.x, p1.y), normal, tangent)
		add_point(context, Vector3(p1.x, height, p2.y), Vector2(p1.x, p2.y), normal, tangent)
		add_point(context, Vector3(p2.x, height, p1.y), Vector2(p2.x, p1.y), normal, tangent)
		add_point(context, Vector3(p2.x, height, p2.y), Vector2(p2.x, p2.y), normal, tangent)
		var ceiling_mesh = MeshInstance.new()
		ceiling_mesh.name = "floor"
		ceiling_mesh.mesh = ArrayMesh.new()
		ceiling_mesh.mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLE_STRIP, [ PoolVector3Array(context.vertices), PoolVector3Array(context.normals), PoolRealArray(context.tangents), null, PoolVector2Array(context.uvs), null, null, null, null ])
		ceiling_mesh.mesh.surface_set_material(0, ceiling_material)
		add_child(ceiling_mesh)


func add_point(context, vertex, uv, normal, tangent):
	context.vertices.append(vertex)
	context.uvs.append(uv)
	context.normals.append(normal)
	context.tangents.append(tangent[0])
	context.tangents.append(tangent[1])
	context.tangents.append(tangent[2])
	context.tangents.append(tangent[3])

func create_vertical_rect(from, to, context):
	var uv_from = from.y
	var uv_to = to.y
	if abs(from.x-to.x) > abs(from.y-to.y):
		uv_from = from.x
		uv_to = to.x
	var normal = Vector3(from.y-to.y, 0, to.x-from.x).normalized()
	var tangent = [normal.z, 0, -normal.x, 1]
	add_point(context, Vector3(from.x, 0, from.y), Vector2(uv_from, 0), normal, tangent)
	add_point(context, Vector3(from.x, height, from.y), Vector2(uv_from, height), normal, tangent)
	add_point(context, Vector3(to.x, 0, to.y), Vector2(uv_to, 0), normal, tangent)
	add_point(context, Vector3(from.x, height, from.y), Vector2(uv_from, height), normal, tangent)
	add_point(context, Vector3(to.x, height, to.y), Vector2(uv_to, height), normal, tangent)
	add_point(context, Vector3(to.x, 0, to.y), Vector2(uv_to, 0), normal, tangent)

func create_wall(from, to, context):
	create_vertical_rect(Vector2(from.x, from.y), Vector2(from.x, to.y), context)
	create_vertical_rect(Vector2(from.x, to.y), Vector2(to.x, to.y), context)
	create_vertical_rect(Vector2(to.x, to.y), Vector2(to.x, from.y), context)
	create_vertical_rect(Vector2(to.x, from.y), Vector2(from.x, from.y), context)
	var center = 0.5*(from+to)
	var extent = to-center
	var shape = CollisionShape.new()
	shape.translation = Vector3(center.x, 0.5*height, center.y)
	shape.shape = BoxShape.new()
	shape.shape.extents = Vector3(extent.x, 0.5*height, extent.y)
	add_child(shape)

func generate_walls_along_x(y, d, context):
	var mask = (1 << d)
	var offset = 0.5*Vector2(DIRECTIONS[d].x, DIRECTIONS[d].y)
	var wall_begin = null
	for x in range(size_x):
		if wall_begin == null && (cells[x][y] & mask) == 0:
			wall_begin = x
		elif wall_begin != null && (cells[x][y] & mask) != 0:
			create_wall(corridor_width*(Vector2(wall_begin-0.5, y)+offset)-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(x-0.5, y)+offset)+0.5*wall_width*Vector2(1, 1), context)
			wall_begin = null
	if wall_begin != null:
		create_wall(corridor_width*(Vector2(wall_begin-0.5, y)+offset)-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(size_x-0.5, y)+offset)+0.5*wall_width*Vector2(1, 1), context)

func generate_walls_along_y(x, d, context):
	var mask = (1 << d)
	var offset = 0.5*Vector2(DIRECTIONS[d].x, DIRECTIONS[d].y)
	var wall_begin = null
	for y in range(size_y):
		if wall_begin == null && (cells[x][y] & mask) == 0:
			wall_begin = y
		elif wall_begin != null && (cells[x][y] & mask) != 0:
			create_wall(corridor_width*(Vector2(x, wall_begin-0.5)+offset)-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(x, y-0.5)+offset)+0.5*wall_width*Vector2(1, 1), context)
			wall_begin = null
	if wall_begin != null:
		create_wall(corridor_width*(Vector2(x, wall_begin-0.5)+offset)-0.5*wall_width*Vector2(1, 1), corridor_width*(Vector2(x, size_y-0.5)+offset)+0.5*wall_width*Vector2(1, 1), context)

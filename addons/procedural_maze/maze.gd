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

export(PackedScene) var loot1
export(PackedScene) var loot2
export(PackedScene) var loot3

export(PackedScene) var light

export(PackedScene) var key
export(PackedScene) var door

var cells = []

const MazeGenerator = preload("res://addons/procedural_maze/maze_generator.gd")

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
	generator.generate(random_seed)
	print("Generated maze in %d seconds" % (OS.get_unix_time() - time))
	time = OS.get_unix_time()
	generator.generate_floor(self, floor_material)
	generator.generate_walls(self, wall_material)
	generator.generate_ceiling(self, ceiling_material)
	print("Generated meshes and collision shapes in %d seconds" % (OS.get_unix_time() - time))

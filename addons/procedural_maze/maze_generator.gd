tool
extends Node

var size_x
var size_y
var corridor_width
var wall_width
var height

var walls_x
var walls_y

var cells = []
var objects = []

const DIRECTIONS = [
	{ v=Vector2(-1, 0), r=1, a=PI },
	{ v=Vector2(0, -1), r=0, a=0.5*PI },
	{ v=Vector2(1, 0),  r=1, a=0.0 },
	{ v=Vector2(0, 1),  r=0, a=-0.5*PI } ]
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
		var line = PoolIntArray()
		for y in range(size_y):
			line.append(0)
		cells.append(line)
	objects = []

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
				if rect.has_point(Vector2(x, y)+0.5*DIRECTIONS[d].v):
					cells[x][y] |= (1 << d)

func generate(random_seed):
	var time = OS.get_unix_time()
	seed(random_seed)
	# Generate maze
	var current = { x=0, y=0 }
	var remaining = size_x*size_y-1
	var stack = []
	var direction
	cells[current.x][current.y] |= MASK_VISITED
	var backtracking = false
	while remaining > 0:
		var choices = []
		for d in range(4):
			var x = current.x+DIRECTIONS[d].v.x
			var y = current.y+DIRECTIONS[d].v.y
			if x >= 0 && y >= 0 && x < size_x && y < size_y && (cells[x][y] & MASK_VISITED) == 0:
				choices.append(d)
		if choices.empty():
			if !backtracking:
				var object = { x=current.x, y=current.y, value=1, direction=direction }
				object.type = "loot"
				objects.append(object)
			if stack.empty():
				break
			current = stack.pop_back()
			backtracking = true
		else:
			direction = choices[randi() % choices.size()]
			stack.append(current.duplicate())
			cells[current.x][current.y] |= (1 << direction)
			current.x += DIRECTIONS[direction].v.x
			current.y += DIRECTIONS[direction].v.y
			cells[current.x][current.y] |= (1 << ((direction + 2) % 4)) | MASK_VISITED
			remaining -= 1
			if backtracking:
				var door_position = Vector2(current.x, current.y)-0.5*DIRECTIONS[direction].v
				var object = { x=door_position.x, y=door_position.y, type="door", value=1, direction=direction }
				objects.append(object)
			backtracking = false
	# Add ending objects if any
	if remaining == 0:
		var object = { x=current.x, y=current.y, type="chest", value=10, direction=direction }
		objects.append(object)
	return objects

func generate_walls():
	walls_x = PoolIntArray()
	generate_walls_along_x(0, DIRECTION_UP)
	for y in range(size_y):
		generate_walls_along_x(y, DIRECTION_DOWN, 1)
	walls_y = PoolIntArray()
	generate_walls_along_y(0, DIRECTION_LEFT)
	for x in range(size_x):
		generate_walls_along_y(x, DIRECTION_RIGHT, 1)
		
func generate_walls_along_x(y, d, offset = 0):
	var mask = (1 << d)
	var wall_begin = null
	for x in range(size_x):
		if wall_begin == null && (cells[x][y] & mask) == 0:
			wall_begin = x
		elif wall_begin != null && (cells[x][y] & mask) != 0:
			walls_x.append(y+offset)
			walls_x.append(wall_begin)
			walls_x.append(x-1)
			wall_begin = null
	if wall_begin != null:
		walls_x.append(y+offset)
		walls_x.append(wall_begin)
		walls_x.append(size_x-1)

func generate_walls_along_y(x, d, offset = 0):
	var mask = (1 << d)
	var wall_begin = null
	for y in range(size_y):
		if wall_begin == null && (cells[x][y] & mask) == 0:
			wall_begin = y
		elif wall_begin != null && (cells[x][y] & mask) != 0:
			walls_y.append(x+offset)
			walls_y.append(wall_begin)
			walls_y.append(y-1)
			wall_begin = null
	if wall_begin != null:
		walls_y.append(x+offset)
		walls_y.append(wall_begin)
		walls_y.append(size_y-1)

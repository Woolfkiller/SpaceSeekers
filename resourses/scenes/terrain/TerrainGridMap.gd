tool
extends Spatial

# Exports
export (int) var terrain_size := 32
export (int) var sector_size := 16
export (float) var noise_period = 20.0
export (float) var noise_octaves = 1
export (float) var noise_persistence = 0.8
export (float) var noise_lacunarity = 2.0
export (float) var ramp_chance = 0.1
export (int) var crystal_chance := 10000

export (bool) var refresh = false
export (bool) var next_sector = false
export (bool) var clean = false

# Constants
enum {
	TILE_PLANE = 0,
	TILE_RAMP,
	TILE_SIDE_CLIFF = 5,
	TILE_SIDE_CORNER = 9,
	TILE_SIDE_CORNER_INNER = 13,
}

enum {
	OBJECT_CRYSTAL_1 = 0,
}

# etc.
onready var grid : GridMap = $TerrainGridMap
onready var obj_grid : GridMap = $ObjectGridMap
var noise_generator: OpenSimplexNoise
var obj_rng = RandomNumberGenerator.new()
var cur_sector: int = 0

func _ready() -> void:	
	if not Engine.editor_hint:
		generate_terrain()


func _process(delta: float) -> void:
	if refresh or (not Engine.editor_hint and Input.is_key_pressed(KEY_F)):
		generate_terrain()
		cur_sector = 0
		refresh = false
	
	if clean or (not Engine.editor_hint and Input.is_key_pressed(KEY_C)):
		grid.clear()
		cur_sector = 0
		clean = false
	
	if next_sector or (not Engine.editor_hint and Input.is_key_pressed(KEY_N)):
		var sector_cnt = pow((terrain_size / sector_size), 2)
		if cur_sector < sector_cnt:
			var point : = Vector2(
				-terrain_size/2 + sector_size * (cur_sector/(terrain_size / sector_size)) + sector_size/2,
				-terrain_size/2 + sector_size * (cur_sector%(terrain_size / sector_size)) + sector_size/2
			)
			generate_sector(point)
			print("Generating sector at: ", point)
			cur_sector += 1
		else:
			print("All sectors generated!")
		next_sector = false


func generate_terrain() -> void:
	## Clearing grid
	grid.clear()
	grid.cell_octant_size = sector_size
	
	shake_noise()
	
	## Generating terrain
	generate_sector(Vector2(0, 0))
	
	## Maybe some terrain fixes
	
	## Spawning objects


func generate_sector(center: Vector2):
	for x in range(center.x - sector_size / 2, center.x + sector_size / 2):
		for y in range(center.y - sector_size / 2, center.y + sector_size / 2):
			var tile_height : float = get_interpolated_height_at_point(x, y) / 0.5
			var tile_type : int = define_tile(x, y)
			grid.set_cell_item(x, tile_height, y, tile_type, 0)
			if ((obj_rng.randi_range(0, crystal_chance) == 0) and (tile_type == 0)):
				var quaternion = Quat(Vector3(0, 1, 0.0), deg2rad(90.0 * obj_rng.randi_range(0, 4)))
				var orientation = Basis(quaternion).get_orthogonal_index()
				obj_grid.set_cell_item(x, tile_height, y, 0, orientation)


func define_tile(x: int, y: int) -> int:
	var tile := {
		"type": 0
	}
	
	var neighbors = check_neighbors(x, y)
	if neighbors & (1 << 0):
		if neighbors & (1 << 2):
			tile.type = TILE_SIDE_CORNER_INNER + 3
		elif neighbors & (1 << 6):
			tile.type = TILE_SIDE_CORNER_INNER
		else:
			if randf() > ramp_chance:
				tile.type = TILE_SIDE_CLIFF + 3
			else:
				tile.type = TILE_RAMP + 3
	elif neighbors & (1 << 2):
		if neighbors & (1 << 4):
			tile.type = TILE_SIDE_CORNER_INNER + 2
		else:
			if randf() > ramp_chance:
				tile.type = TILE_SIDE_CLIFF + 2
			else:
				tile.type = TILE_RAMP + 2
	elif neighbors & (1 << 4):
		if neighbors & (1 << 6):
			tile.type = TILE_SIDE_CORNER_INNER + 1
		else:
			if randf() > ramp_chance:
				tile.type = TILE_SIDE_CLIFF + 1
			else:
				tile.type = TILE_RAMP + 1
	elif neighbors & (1 << 6):
		if randf() > ramp_chance:
			tile.type = TILE_SIDE_CLIFF
		else:
			tile.type = TILE_RAMP
	elif neighbors & (1 << 1):
		tile.type = TILE_SIDE_CORNER + 3
	elif neighbors & (1 << 3):
		tile.type = TILE_SIDE_CORNER + 2
	elif neighbors & (1 << 5):
		tile.type = TILE_SIDE_CORNER + 1
	elif neighbors & (1 << 7):
		tile.type = TILE_SIDE_CORNER
	else:
		tile.type = TILE_PLANE
	
	return tile.type


func check_neighbors(x: float, y: float):
	var res = 0
	var angle = 0.0
	var base_height : float = get_interpolated_height_at_point(x, y)
	for i in 8:
		angle = deg2rad(i * 45);
		if (get_interpolated_height_at_point(x + good_sign(cos(angle)), y + good_sign(sin(angle))) - base_height) > 0:
			res = res|(1 << i)
	return res


func get_interpolated_height_at_point(x, y):
	var height = get_height_at_point(x, y)
	var height_x0 = get_height_at_point(x-1, y)
	var height_x1 = get_height_at_point(x+1, y)
	var height_y0 = get_height_at_point(x, y-1)
	var height_y1 = get_height_at_point(x, y+1)
	
	if height < height_x0 and (height_x0 == height_x1):
		return height_x0
	elif height < height_y0 and (height_y0 == height_y1):
		return height_y0
	else:
		return height


func get_height_at_point(x, y) -> float:
	return int(noise_generator.get_noise_2d(x, y) * 3) * 0.5


func shake_noise():
	## Configuring noise generator
	noise_generator = OpenSimplexNoise.new()
	noise_generator.seed = OS.get_ticks_msec()
	noise_generator.octaves = noise_octaves
	noise_generator.period = noise_period
	noise_generator.persistence = noise_persistence
	noise_generator.lacunarity = noise_lacunarity
	
	obj_rng.randomize()


func good_sign(num):
	if num > 0.1:
		return 1
	elif num < -0.1:
		return -1
	else:
		return 0


func populate_with_objects():
	pass

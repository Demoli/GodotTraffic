extends CharacterBody2D

var movement_speed: float = 400.0
var movement_target: Vector2
var prev_movement_target: Vector2

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var tilemap : TileMap = get_node("../Map1")

@export var lane = 0
@export var direction : Vector2 = Vector2.RIGHT

var last_tile
var tile

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	$NavigationAgent2D.set_navigation_map(tilemap.get_navigation_map(lane))
	

func _input(event):
	if event.is_action_pressed("goto"):
		set_movement_target(get_global_mouse_position())
#		set_movement_target(position + Vector2(100, 0))
		

func set_movement_target(movement_target: Vector2):
	movement_target = movement_target
	navigation_agent.target_position = movement_target

func _physics_process(_delta):
	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position: Vector2 = global_transform.origin
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	next_path_position = next_path_position.round()

	tile = tilemap.get_cell_tile_data(0, tilemap.local_to_map(position))
	var can_turn = tile.get_custom_data("can_turn")
	var target_direction = position.direction_to(next_path_position).round()
	
	if can_turn and tile != last_tile:
		print(target_direction)
		if direction == Vector2.RIGHT and target_direction == Vector2.UP:
			prev_movement_target = movement_target
			movement_target = position + Vector2(128 - 10, 0)
			set_movement_target(movement_target)
			next_path_position = navigation_agent.get_next_path_position()
	
	if prev_movement_target != Vector2() and position.distance_to(next_path_position) < 5:
		set_movement_target(prev_movement_target)
		prev_movement_target = Vector2()
		next_path_position = navigation_agent.get_next_path_position()
	
	var new_velocity: Vector2 = next_path_position - current_agent_position
	new_velocity = new_velocity.normalized()
	new_velocity = new_velocity * movement_speed

	direction = target_direction

	set_velocity(new_velocity)
	move_and_slide()
	look_at(position + direction)

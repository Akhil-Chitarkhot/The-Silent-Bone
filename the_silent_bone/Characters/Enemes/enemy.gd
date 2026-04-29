extends CharacterBody3D

enum State { PATROL, INVESTIGATE, CHASE }
var current_state = State.PATROL
var is_attacking = false 

@export var patrol_points: Array[Marker3D] # Drag your markers here in the inspector
var current_index = 0
var last_known_pos = Vector3.ZERO

@onready var animation_player: AnimationPlayer = $Barbarian/AnimationPlayer
@onready var nav_agent = $NavigationAgent3D
@onready var ray = $RayCast3D

func _physics_process(_delta):
	if is_attacking:
		return
	match current_state:
		State.PATROL:
			move_to_position(patrol_points[current_index].global_position)
			# If we reach the point, go to the next one
			if nav_agent.is_navigation_finished():
				current_index = (current_index + 1) % patrol_points.size()
			check_for_player()

		State.INVESTIGATE:
			move_to_position(last_known_pos)
			if nav_agent.is_navigation_finished():
				# Wait logic could go here with a Timer node
				await get_tree().create_timer(3.0).timeout
				current_state = State.PATROL

		State.CHASE:
			var player = get_tree().get_first_node_in_group("Player")
			move_to_position(player.global_position)
			# If player hides behind a wall
			if not can_see_player(player):
				last_known_pos = player.global_position
				current_state = State.INVESTIGATE
				
	update_animations()

func move_to_position(target: Vector3):
	nav_agent.target_position = target
	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	
	velocity = direction * 3.0 # Speed
	move_and_slide()
	
	# Rotate the model to look where it's walking
	if velocity.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

func check_for_player():
	var player = get_tree().get_first_node_in_group("Player")
	if player and can_see_player(player):
		current_state = State.CHASE

func can_see_player(target_player) -> bool:
	# 1. Aim for the center of the player (head/chest height)
	var target_vector = target_player.global_position + Vector3(0, 1.2, 0)
	
	# 2. Use 'look_at' but ensure we use the global coordinate
	ray.look_at(target_vector, Vector3.UP)
	
	# 3. CRITICAL: Force the physics engine to see the new rotation 
	# before we check for a collision in the same frame
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var collider = ray.get_collider()
		# Check if the thing hit is the player
		if collider.is_in_group("Player"):
			return true
			
	return false
	
func update_animations():
	if velocity.length() > 0.1:
		if current_state == State.CHASE:
			animation_player.play("player_animations/Running_B")
		else:
			animation_player.play("player_animations/Walking_A")
	else:
		animation_player.play("player_animations/Idle_A")
	
	


func _on_killzone_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and not is_attacking:
		attack_player(body)
		
func attack_player(player: Node3D) -> void:
	is_attacking = true
	current_state = State.PATROL  # Stop chasing while attacking
	velocity = Vector3.ZERO       # Stop moving

	# Play enemy hit/attack animation
	animation_player.play("player_animations/Throw")
	await animation_player.animation_finished

	# Tell the player to die
	if player and is_instance_valid(player):
		player.die()

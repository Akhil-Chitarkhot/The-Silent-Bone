extends CharacterBody3D

@onready var Skeleton_minion: Node3D = %Skeleton_Minion
@onready var animation_player: AnimationPlayer = $Skeleton_Minion/AnimationPlayer
@onready var player_camera: Camera3D = $Cam_Mount/TP_Cam/v/PlayerCamera
var is_dead = false

const SPEED = 5.0
const JUMP_VELOCITY = 4.5


func _input(event):
	if event.is_action_pressed("ui_cancel"): get_tree().quit()


func _set_animation(direction):
	if direction:
		var targetAngle = atan2(direction.x, direction.z) - rotation.y
		Skeleton_minion.rotation.y = lerp_angle(Skeleton_minion.rotation.y, targetAngle, 0.1)

		animation_player.play("player_animations/Running_A")
	else:
		animation_player.play("player_animations/Idle_B")

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	# Play death animation
	animation_player.play("player_animations/Death_B")  # ⚠️ Change to your actual animation name
	await animation_player.animation_finished
	
	 # Wait a moment so the player sees the animation
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()
	
	

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction = (player_camera.global_transform.basis  * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	_set_animation(direction)
	
	move_and_slide()
	

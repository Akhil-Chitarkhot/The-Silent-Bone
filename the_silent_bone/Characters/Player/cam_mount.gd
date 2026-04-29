extends Node3D

@export var TP_Cam_sensitivity := 0.003
@export var v_sensitivity := 0.003
@export var TP_Cam_acceleration := 11.0
@export var v_acceleration := 11.0
@export var cam_v_max_deg := 75.0
@export var cam_v_min_deg := -55.0


@onready var v_spring_arm: Node3D = $TP_Cam/v
@onready var player_camera: Camera3D = $TP_Cam/v/PlayerCamera

var camrot_TP_Cam := 0.0
var camrot_v := 0.0

@onready var TP_Cam_pivot: Node3D = $TP_Cam

func _ready () -> void:

	# Initialize rotation from current rig pose
	camrot_TP_Cam = TP_Cam_pivot.rotation.y
	camrot_v = v_spring_arm.rotation.x

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED




func _physics_process(delta: float) -> void:
	# Follow target

	# Clamp vertical look
	camrot_v = clamp(camrot_v, deg_to_rad(cam_v_min_deg), deg_to_rad(cam_v_max_deg))

	# Smooth rotations
	TP_Cam_pivot.rotation.y = lerpf(TP_Cam_pivot.rotation.y, camrot_TP_Cam, delta * TP_Cam_acceleration)
	v_spring_arm.rotation.x = lerpf(v_spring_arm.rotation.x, camrot_v, delta * v_acceleration)
	
	

func _input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion:
		camrot_TP_Cam += -event.relative.x * TP_Cam_sensitivity
		camrot_v += event.relative.y * v_sensitivity
		
	# ESC key to free the mouse (useful for debugging)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

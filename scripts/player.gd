extends CharacterBody3D

## Third-person knight controller.
## Expects this node structure:
##   Player (CharacterBody3D)  <- this script
##     CollisionShape3D        <- capsule
##     Mesh                    <- Node3D, holds the visible model
##     CameraPivot             <- Node3D, sits at chest height
##       SpringArm3D           <- pulls camera in when it hits a wall
##         Camera3D

@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003
@export var turn_speed: float = 10.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var mesh: Node3D = $Mesh

# How far up and down you can look, in degrees.
const PITCH_MIN := deg_to_rad(-60.0)
const PITCH_MAX := deg_to_rad(30.0)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# Escape releases the mouse so you can get back to the editor.
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw turns the whole pivot; pitch only tilts the arm.
		# Keeping them on separate nodes is what stops the camera rolling.
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clampf(spring_arm.rotation.x, PITCH_MIN, PITCH_MAX)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Move relative to where the camera is looking, not where the knight faces.
	# This is the whole trick of third-person movement.
	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		var cam_basis := camera_pivot.global_transform.basis
		direction = cam_basis.x * input_dir.x + cam_basis.z * input_dir.y
		direction.y = 0.0
		direction = direction.normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		# Turn the model to face travel direction. Godot models face -Z at
		# rotation 0, which is where the two minus signs come from.
		var target_yaw := atan2(-direction.x, -direction.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()

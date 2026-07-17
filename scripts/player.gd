extends CharacterBody3D

## Third-person knight controller with animation.
## Expects:
##   Player (CharacterBody3D)   <- this script
##     CollisionShape3D
##     Mesh (Node3D)
##       Knight                 <- made local, from Knight.glb
##         Skeleton3D
##         AnimationPlayer      <- libraries "move" and "general" loaded
##     CameraPivot (Node3D)
##       SpringArm3D
##         Camera3D

@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003
@export var turn_speed: float = 10.0

## Animation names are exported so you can swap them in the inspector without
## touching code. KayKit ships variants - Walking_A/B/C, Idle_A/B, Running_A/B.
## Try them and keep whichever looks right.
@export_group("Animation")
@export var idle_anim: String = "general/Idle_A"
@export var walk_anim: String = "move/Walking_B"
@export var jump_anim: String = "move/Jump_Idle"
## Crossfade time between animations. 0 snaps, 0.2 is a soft blend.
@export var anim_blend: float = 0.2

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var mesh: Node3D = $Mesh
@onready var anim: AnimationPlayer = $Mesh/Knight/AnimationPlayer

const PITCH_MIN := deg_to_rad(-60.0)
const PITCH_MAX := deg_to_rad(30.0)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# glTF animations import with looping switched off, so a walk cycle plays
	# once and freezes on the last frame. Looks like a bug, isn't one.
	_set_looping(idle_anim)
	_set_looping(walk_anim)

	anim.play(idle_anim)


func _set_looping(anim_name: String) -> void:
	if not anim.has_animation(anim_name):
		# Wrong name? You'll see this in the Output panel instead of silently
		# getting a T-pose with no explanation.
		push_warning("Animation not found: %s" % anim_name)
		return
	anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clampf(spring_arm.rotation.x, PITCH_MIN, PITCH_MAX)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		var cam_basis := camera_pivot.global_transform.basis
		direction = cam_basis.x * input_dir.x + cam_basis.z * input_dir.y
		direction.y = 0.0
		direction = direction.normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		var target_yaw := atan2(-direction.x, -direction.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	# Pick the animation that matches what the body is actually doing, rather
	# than what the player pressed. Means it can never disagree with the physics.
	var target := idle_anim

	if not is_on_floor():
		target = jump_anim
	else:
		var flat_speed := Vector2(velocity.x, velocity.z).length()
		if flat_speed > 0.2:
			target = walk_anim

	# Guard the play() call. Without this you'd restart the animation from frame
	# zero every physics tick, and the knight would twitch instead of walk.
	if anim.current_animation != target:
		anim.play(target, anim_blend)
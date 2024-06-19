extends CharacterBody3D

@onready var cam_mount = $cam_mount
@onready var camera_3d = $cam_mount/Camera3D

const SPEED = 4
const JUMP_VELOCITY = 4.5

var came_base_height = 1.4

var walk_sin_offset = 0
var walk_sin_speed = 9.5
var walk_sin_height = 0.08

var perma_shake_speed = 0.5
var perma_shake_timer = 0

var perma_shake_height = 0.01
var perma_shake_width = 0.01

var current_camera_offset = Vector3.ZERO
var wanted_camera_offset = Vector3.ZERO

var mouse_sense = 0.2 / 2.5

var sway_offset = Vector3.ZERO
var sway_intensity = 25
var sway_speed = 25

var camera_animation_speed = 3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	#get mouse input for camera rotation
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		cam_mount.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		cam_mount.rotation.x = clamp(cam_mount.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
		sway_offset.x += event.relative.x
		sway_offset.y += event.relative.y

func _process(delta):
	perma_shake_timer += delta
	
	if perma_shake_timer > perma_shake_speed:
		# Idle camera shake
		wanted_camera_offset = Vector3(randf_range(-perma_shake_width/2, perma_shake_width/2),randf_range(-perma_shake_height/2, perma_shake_height/2),0)
		perma_shake_timer = 0

func _physics_process(delta):
	# Moving camera shake effect
	camera_3d.position = current_camera_offset
	$cam_mount/Camera3D/Control/TextureRect.position.x = -10 -current_camera_offset.x * 100
	$cam_mount/Camera3D/Control/TextureRect.position.y = -10 -current_camera_offset.y * 100
	
	current_camera_offset = lerp(current_camera_offset, wanted_camera_offset, camera_animation_speed * delta)
	
	# Gun sway
	sway_offset = lerp(sway_offset, Vector3.ZERO, delta * sway_speed)
	$cam_mount/gun_handler.rotation = Vector3(deg_to_rad(sway_offset.y) / sway_intensity, -(deg_to_rad(sway_offset.x) / sway_speed) - deg_to_rad(0), 0)
	
	# Add the gravity.
	if not is_on_floor(): 
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		walk_sin_offset += delta*walk_sin_speed
		cam_mount.position.y = (sin(walk_sin_offset) * walk_sin_height) + came_base_height
		
		# Camera move sway
		camera_3d.rotation.z = lerp_angle(camera_3d.rotation.z, -deg_to_rad(velocity.x * 1), delta * 10)
		camera_3d.rotation.x = lerp_angle(camera_3d.rotation.x, deg_to_rad(velocity.z * 1), delta * 10)
		
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED / 2
		
		# Gun sway
		$cam_mount/gun_handler.position.y = lerp($cam_mount/gun_handler.position.y, -0.3, delta * 10)
	else:
		# Camera move sway
		camera_3d.rotation.z = lerp_angle(camera_3d.rotation.z, 0, delta * 10)
		camera_3d.rotation.x = lerp_angle(camera_3d.rotation.x, 0, delta * 10)
		
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		# Gun sway
		$cam_mount/gun_handler.position.y = lerp($cam_mount/gun_handler.position.y, -0.25, delta * 10)

	move_and_slide()

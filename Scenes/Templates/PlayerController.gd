class_name PlayerController
extends CharacterBody3D

@onready var camera: Camera3D = %Camera
@onready var player_ui: PlayerUI = $PlayerUi

# Camera Settings
const LOOK_SENSITIVITY: float = 0.006
var _saved_camera_global_pos = null
@export var look_sensitivity_modifier: float = 1.0
@export var camera_fov: float = 90.0

# Movement Settings
const CROUCH_TRANSLATE: float = 0.5
const CROUCH_JUMP_ADD: float = CROUCH_TRANSLATE * 0.9
const MAX_STEP_HEIGHT: float = 0.515
var _snapped_to_stairs_last_frame: bool = false
var _last_frame_was_on_floor: float = -INF
var is_crouching: bool = false
@export var jump_velocity: float = 6.0
@export var default_move_speed: float = 7
@export var sprint_speed_modifier: float = 1.25
@export var crouch_speed_modifier: float = 0.65
@export var ground_acceleration: float = 14.0
@export var ground_deceleration: float = 10.0
@export var ground_friction: float = 6.0
@export var air_cap: float = 0.85
@export var air_acceleration: float = 800.0
@export var air_move_speed: float = 500.0
@export var can_move: bool = true
@onready var _original_capsule_height = $Collider.shape.height

@export var input_locked: bool = false
var camera_zoomed: bool = false

var wish_direction: Vector3 = Vector3.ZERO
var cam_aligned_wish_direction: Vector3 = Vector3.ZERO

var noclip_speed_multiplier: float = 3.0
var noclip: bool = false

func get_head_height() -> Vector3:
	return $HeadOriginalPosition.position + %Head.position

func get_look_sensitivity() -> float:
	return (LOOK_SENSITIVITY * 1.0) * look_sensitivity_modifier

func is_sprinting() -> bool:
	return Input.is_action_pressed("sprint") and not is_crouching

func get_move_speed() -> float:
	var move_speed: float = 0.0
	if not can_move: return move_speed
	move_speed = default_move_speed
	if is_sprinting(): move_speed *= sprint_speed_modifier
	if is_crouching: move_speed *= crouch_speed_modifier
	return move_speed

func update_camera_fov() -> void:
	camera.fov = camera_fov

func unstuck() -> void:
	self.global_position = Vector3.ZERO

func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.fov = ConfigHandler.load_graphics_settings().get("fov")
	GameManager.player_reference = self
	for child in %WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)

func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
	#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if input_locked: return
	if event.is_action_pressed("ui_cancel"):
		# TODO: Make pause screen not appear while backing out of computer
		$PauseScreen.pause()
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			var look_sensitivity = get_look_sensitivity()
			rotate_y(-event.relative.x * look_sensitivity)
			%Camera.rotate_x(-event.relative.y * look_sensitivity)
			%Camera.rotation.x = clamp(%Camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			noclip_speed_multiplier = min(100.0, noclip_speed_multiplier * 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			noclip_speed_multiplier = max(0.1, noclip_speed_multiplier * 0.9)

func _process(delta: float) -> void:
	if camera_zoomed: return
	var interactable: Interactable = get_interactable_at_shapecast()
	if interactable:
		$PlayerUi.update_label(interactable.interact_name)
		if Input.is_action_just_pressed("interact"):
			interactable.interact_with(self)
	else:
		$PlayerUi.update_label("")

func get_interactable_at_shapecast() -> Interactable:
	for i in %InteractCast.get_collision_count():
		if i > 0 and %InteractCast.get_collider(0) != $".":
			return null
		var node_or_null: Node = %InteractCast.get_collider(i).get_node_or_null("Interactable")
		if node_or_null is Interactable:
			return node_or_null
	return null

func _save_camera_pos_for_smoothing() -> void:
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = %CameraSmooth.global_position

func _slide_camera_smooth_back_to_origin(delta):
	if _saved_camera_global_pos == null: return
	%CameraSmooth.global_position.y = _saved_camera_global_pos.y
	%CameraSmooth.position.y = clampf(%CameraSmooth.position.y, -0.7, 0.7)
	var move_amount = max(self.velocity.length() * delta, (default_move_speed * 0.5) * delta)
	%CameraSmooth.position.y = move_toward(%CameraSmooth.position.y, 0.0, move_amount)
	_saved_camera_global_pos = %CameraSmooth.global_position
	if %CameraSmooth.position.y == 0:
		_saved_camera_global_pos = null

func _push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var collider: KinematicCollision3D = get_slide_collision(i)

func _snap_down_to_stairs_check() -> void:
	var did_snap: bool = false
	%StairsBelowRaycast.force_raycast_update()
	var floor_below: bool = %StairsBelowRaycast.is_colliding() and not is_surface_too_steep(%StairsBelowRaycast.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() == _last_frame_was_on_floor
	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last_frame or _snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = KinematicCollision3D.new()
		if self.test_move(self.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), body_test_result):
			_save_camera_pos_for_smoothing()
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	_snapped_to_stairs_last_frame = did_snap

func _snap_up_stairs_check(delta: float) -> bool:
	if not is_on_floor() and not _snapped_to_stairs_last_frame: return false
	if self.velocity.y > 0 or (self.velocity * Vector3(1,0,1)).length() == 0: return false
	var expected_move_motion = self.velocity * Vector3(1, 0, 1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	var down_check_result = KinematicCollision3D.new()
	if (self.test_move(step_pos_with_clearance, Vector3(0, -MAX_STEP_HEIGHT * 2, 0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_position() - self.global_position).y > MAX_STEP_HEIGHT: return false
		%StairsAheadRaycast.global_position = down_check_result.get_position() + Vector3(0, MAX_STEP_HEIGHT, 0) + expected_move_motion.normalized() * 0.1
		%StairsAheadRaycast.force_raycast_update()
		if %StairsAheadRaycast.is_colliding() and not is_surface_too_steep(%StairsAheadRaycast.get_collision_normal()):
			_save_camera_pos_for_smoothing()
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs_last_frame = true
			return true
		   
	return false

func _handle_crouch(delta: float) -> void:
	var was_crouching_last_frame: bool = is_crouching
	if Input.is_action_pressed("crouch"):
		is_crouching = true
	elif is_crouching and not self.test_move(self.global_transform, Vector3(0, CROUCH_TRANSLATE, 0)):
		is_crouching = false
	
	var translate_y_if_possible: float = 0.0
	if was_crouching_last_frame != is_crouching and not is_on_floor() and not _snapped_to_stairs_last_frame:
		translate_y_if_possible = CROUCH_JUMP_ADD if is_crouching else -CROUCH_JUMP_ADD
	
	if translate_y_if_possible != 0.0:
		var result = KinematicCollision3D.new()
		self.test_move(self.global_transform, Vector3(0, translate_y_if_possible, 0), result)
		self.position.y += result.get_travel().y
		%Head.position.y -= result.get_travel().y
		%Head.position.y = clampf(%Head.position.y, -CROUCH_TRANSLATE, 0)
	
	%Head.position.y = move_toward(%Head.position.y, -CROUCH_TRANSLATE if is_crouching else 0, 7.0 * delta) # Arg 3 is smoothing time, not worth its own var atp
	$Collider.shape.height = _original_capsule_height - CROUCH_TRANSLATE if is_crouching else _original_capsule_height
	$Collider.position.y = $Collider.shape.height * 0.5

func _handle_noclip(delta: float) -> bool:
	if Input.is_action_just_pressed("noclip") and OS.has_feature("debug"):
		noclip = !noclip
		noclip_speed_multiplier = 3.0
	
	$Collider.disabled = noclip
	
	if not noclip:
		return false
	
	var speed = get_move_speed() * noclip_speed_multiplier
	if Input.is_action_pressed("sprint"):
		speed *= 3.0
	
	self.velocity = cam_aligned_wish_direction * speed
	global_position += self.velocity * delta
	
	return true

func clip_velocity(normal: Vector3, overbounce: float, delta: float) -> void:
	var backoff: float = self.velocity.dot(normal) * overbounce
	if backoff >= 0: return
	
	var change: Vector3 = normal * backoff
	self.velocity -= change
	
	var adjust: float = self.velocity.dot(normal)
	if adjust < 0.0:
		self.velocity -= normal * adjust

func is_surface_too_steep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle

func _handle_air_physics(delta: float) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	var current_speed_in_wish_direction = self.velocity.dot(wish_direction)
	
	var capped_speed = min((air_move_speed * wish_direction).length(), air_cap)
	var add_speed_until_cap = capped_speed - current_speed_in_wish_direction
	if add_speed_until_cap > 0:
		var acceleration_speed = air_acceleration * air_move_speed * delta
		acceleration_speed = min(acceleration_speed, add_speed_until_cap)
		self.velocity += acceleration_speed * wish_direction
	
	if is_on_wall():
		if is_surface_too_steep(get_wall_normal()):
			self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			self.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		clip_velocity(get_wall_normal(), 1 ,delta)

func _handle_ground_physics(delta: float) -> void:
	var move_speed = get_move_speed()
	var current_speed_in_wish_direction = self.velocity.dot(wish_direction)
	var add_speed_until_cap = move_speed - current_speed_in_wish_direction
	if add_speed_until_cap > 0:
		var acceleration_speed = ground_acceleration * delta * move_speed
		acceleration_speed = min(acceleration_speed, add_speed_until_cap)
		self.velocity += acceleration_speed * wish_direction
	
	var control = max(self.velocity.length(), ground_deceleration)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed

func _physics_process(delta: float) -> void:
	if is_on_floor(): _last_frame_was_on_floor = Engine.get_physics_frames()
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	wish_direction = self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	cam_aligned_wish_direction = %Camera.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	if not _handle_noclip(delta):
		_handle_crouch(delta)
		if is_on_floor() or _snapped_to_stairs_last_frame:
			if Input.is_action_just_pressed("jump") and can_move:
				self.velocity.y = jump_velocity
			_handle_ground_physics(delta)
		else:
			_handle_air_physics(delta)
		
		if not _snap_up_stairs_check(delta):
			move_and_slide()
			_snap_down_to_stairs_check()
		
		# TODO: Fix. (still)
		#camera.rotation.z = lerp(camera.rotation.z, (Vector2(self.velocity.x, self.velocity.z).length() * input_dir.x) * -0.005, 0.25)
		
	_slide_camera_smooth_back_to_origin(delta)

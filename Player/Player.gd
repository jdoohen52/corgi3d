extends KinematicBody

var direction = Vector3.BACK
var velocity = Vector3.ZERO
var strafe_dir = Vector3.ZERO
var strafe = Vector3.ZERO

var aim_turn = 0

var vertical_velocity = 0
var gravity = 20

var movement_speed = 0
var walk_speed = 1.5
var run_speed = 5
var acceleration = 6
var angular_acceleration = 7

var roll_magnitude = 17

func _ready():
	direction = Vector3.BACK.rotated(Vector3.UP, $Camroot/h.global_transform.basis.get_euler().y)
	# Sometimes in the level design you might need to rotate the Player object itself
	# So changing the direction at the beginning

#	var material = SpatialMaterial.new()
#	material.albedo_color = Color( 0, 1, 1, 1 )
#	$Mesh/corgi_anim/Skeleton/Mesh_Corgi002.set_surface_material(0, material)

	var skel = get_node("Mesh/corgi_anim/Skeleton")
	var b = skel.find_bone("spine_3")
	var rest = skel.get_bone_rest(b)
	var newrest = rest.translated(Vector3(0.0, 0.1, 0.0))
	skel.set_bone_rest(b, newrest)	
	
	var face: SpatialMaterial = load("res://Player/M_Corgi.material")
	var texture = face.get_texture(0)
	var image : Image = texture.get_data()
	image.lock()
	var mean = [0,0,0,0]
	var stddev = [0,0,0,0]
	var count = image.get_height() * image.get_width()
	for y in image.get_height():
		for x in image.get_width():
			var color = image.get_pixel(x, y)
			mean[0] += color.r
			mean[1] += color.g
			mean[2] += color.b

	mean[0] = mean[0] / count
	mean[1] = mean[1] / count
	mean[2] = mean[2] / count

	for y in image.get_height():
		for x in image.get_width():
			var color = image.get_pixel(x, y)
			stddev[0] += pow(color.r - mean[0], 2)
			stddev[1] += pow(color.g - mean[1], 2)
			stddev[2] += pow(color.b - mean[2], 2)

	stddev[0] /= sqrt(stddev[0]/count)
	stddev[1] /= sqrt(stddev[1]/count)
	stddev[2] /= sqrt(stddev[2]/count)

	var target = Color.blue
	for y in image.get_height():
		for x in image.get_width():
			var color = image.get_pixel(x, y)
			if color.r - color.b > 0.3:
				var r = max(0, min(1, (color.r - mean[0])*(target.r/mean[0])+target.r))
				var g = max(0, min(1, (color.g - mean[1])*(target.g/mean[1])+target.g))
				var bb = max(0, min(1, (color.b - mean[2])*(target.b/mean[2])+target.b))

				image.set_pixel(x, y, Color(r,g,bb,1))
	image.unlock()
	texture.create_from_image(image)
	face.set_texture(0, texture)
	$Mesh/corgi_anim/Skeleton/Mesh_Corgi002.material_override = face

	
func _input(event):
	
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015 #animates player with mouse movement while aiming (used in line 104)
	
	if event is InputEventKey: #checking which buttons are being pressed
		if event.as_text() == "W" || event.as_text() == "A" || event.as_text() == "S" || event.as_text() == "D" || event.as_text() == "Space"|| event.as_text() == "J":
			if event.pressed:
				get_node("Status/" + event.as_text()).color = Color("ff6666")
			else:
				get_node("Status/" + event.as_text()).color = Color("ffffff")

	if !$AnimationTree.get("parameters/roll/active"): # The "Tap To Roll" system
		if event.is_action_pressed("sprint"):
			if $roll_window.is_stopped():
				$roll_window.start()
				
		if event.is_action_released("sprint"):
			if !$roll_window.is_stopped():
				velocity = Vector3( 0, 1, 0 ) * roll_magnitude
				$roll_window.stop()
				$AnimationTree.set("parameters/roll/active", true)
				$AnimationTree.set("parameters/aim_transition/current", 1)
				$roll_timer.start()
				
	if !$AnimationTree.get("parameters/attack/active"): # The "Tap To Roll" system
		if event.is_action_pressed("attack"):
			if $roll_window.is_stopped():
				$roll_window.start()
				
		if event.is_action_released("attack"):
			if !$roll_window.is_stopped():
				$roll_window.stop()
				$AnimationTree.set("parameters/attack/active", true)
				$roll_timer.start()

func _physics_process(delta):
	
	if !$roll_timer.is_stopped():
		acceleration = 3.5
	else:
		acceleration = 5
	
	if Input.is_action_pressed("aim"):
		$Status/Aim.color = Color("ff6666")
		if !$AnimationTree.get("parameters/roll/active"):
			$AnimationTree.set("parameters/aim_transition/current", 0)
	else:
		$Status/Aim.color = Color("ffffff")
		$AnimationTree.set("parameters/aim_transition/current", 1)
	
	
	var h_rot = $Camroot/h.global_transform.basis.get_euler().y
	
	if Input.is_action_pressed("forward") ||  Input.is_action_pressed("backward") ||  Input.is_action_pressed("left") ||  Input.is_action_pressed("right"):
		
		direction = Vector3(Input.get_action_strength("left") - Input.get_action_strength("right"),
					0,
					Input.get_action_strength("forward") - Input.get_action_strength("backward"))

		strafe_dir = direction
		
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
		
		if Input.is_action_pressed("sprint") && $AnimationTree.get("parameters/aim_transition/current") == 1:
			movement_speed = run_speed
#			$AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($AnimationTree.get("parameters/iwr_blend/blend_amount"), 1, delta * acceleration))
		else:
			movement_speed = walk_speed
#			$AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($AnimationTree.get("parameters/iwr_blend/blend_amount"), 0, delta * acceleration))
	else:
#		$AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($AnimationTree.get("parameters/iwr_blend/blend_amount"), -1, delta * acceleration))
		movement_speed = 0
		strafe_dir = Vector3.ZERO
		
		if $AnimationTree.get("parameters/aim_transition/current") == 0:
			direction = $Camroot/h.global_transform.basis.z
	
	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)

# warning-ignore:return_value_discarded
	move_and_slide(velocity + Vector3.DOWN * vertical_velocity, Vector3.UP)
	
	if !is_on_floor():
		vertical_velocity += gravity * delta
	else:
		vertical_velocity = 0
	
	
	if $AnimationTree.get("parameters/aim_transition/current") == 1:
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * angular_acceleration)
		# Sometimes in the level design you might need to rotate the Player object itself
		# - rotation.y in case you need to rotate the Player object
	else:
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, $Camroot/h.rotation.y, delta * angular_acceleration)
		# lerping towards $Camroot/h.rotation.y while aiming, h_rot(as in the video) doesn't work if you rotate Player object
		
	
	strafe = lerp(strafe, strafe_dir + Vector3.RIGHT * aim_turn, delta * acceleration)
	
	$AnimationTree.set("parameters/strafe/blend_position", Vector2(-strafe.x, strafe.z))
	
	var iw_blend = (velocity.length() - walk_speed) / walk_speed
	var wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)

	#find the graph here: https://www.desmos.com/calculator/4z9devx1ky

	if velocity.length() <= walk_speed:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , iw_blend)
	else:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , wr_blend)
	
	aim_turn = 0
	
	
#	$Status/Label.text = "direction : " + String(direction)
#	$Status/Label2.text = "direction.length() : " + String(direction.length())
#	$Status/Label3.text = "velocity : " + String(velocity)
#	$Status/Label4.text = "velocity.length() : " + String(velocity.length())



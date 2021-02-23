extends KinematicBody2D

const up = Vector2(0, -1)
const gravity = 20
const maxfallspeed = 200
const maxspeed = 80
const accel = 10
const jumpforce = 350

var motion = Vector2()
var facing_right = true
var attacking = false


func _ready():
	pass # Replace with function body.

# warning-ignore:unused_argument
func _physics_process(delta):
	
	if !facing_right:
		$Sprite.scale.x = -1
	else:
		$Sprite.scale.x = 1
	
	motion.y += gravity
	if motion.y > maxfallspeed:
		motion.y = maxfallspeed
	
	motion.x = clamp(motion.x, -maxspeed, maxspeed)
	
	if Input.is_action_pressed("Right"):
		if !attacking:
			motion.x += accel
			facing_right = true
			$AnimationPlayer.play("Walk")
	elif Input.is_action_pressed("Left"):
		if !attacking:
			motion.x -= accel
			facing_right = false
			$AnimationPlayer.play("Walk")
	else:
		motion.x = lerp(motion.x, 0, 0.1)
		if !attacking:
			$AnimationPlayer.play("Idle")
	
	if is_on_floor():
		if Input.is_action_just_pressed("Jump"):
			motion.y = -jumpforce
			lerp(motion.x, 0, 0.2)
	
	if !is_on_floor() and !attacking:
		if motion.y > 1:
			$AnimationPlayer.play("Fall")
		elif motion.y < 0:
			$AnimationPlayer.play("Jump")
	
	if Input.is_action_just_pressed("Attack"):
		attacking = true
		$AnimationPlayer.play("Attack")
		$AnimationPlayer.queue("Attack End")
		yield($AnimationPlayer, "animation_finished")
	
	if $AnimationPlayer.current_animation_position != 0.7 and attacking:
		if Input.is_action_pressed("Attack"):
			$AnimationPlayer.clear_queue()
			$AnimationPlayer.play("Attack Combo")
			$AnimationPlayer.queue("Attack End")
			yield($AnimationPlayer, "animation_finished")
	
	
	
	motion = move_and_slide(motion, up)

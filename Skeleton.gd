extends KinematicBody2D

onready var hp_bar = get_node("Hp_bar")
onready var hp_timer = get_node("Hp_bar/Hpbar timer")
onready var hp_tween = get_node("Hp_bar/Tween")
onready var player = get_parent().get_node("Character")

var rng = RandomNumberGenerator.new()

var gravityforce = 20
var maxfallspeed = 200
var gravity_on = true

var accel = 10
var maxspeed = 60
var facing_right
var motion = Vector2()
var move_direction = Vector2()
var steady = true

var maxhealth = 100
var currenthealth
var hp_percentage
var state = "Idle"
var previous_state

var can_attack = true
var attacking = false
var attackdamage = 20

var player_in_range



func _ready():
	currenthealth = maxhealth
	hpBarUpdate()
	hp_bar.hide()
	add_to_group("Enemies")
	
	if rng.randi_range(0, 1) == 1:
		facing_right = true
	else:
		facing_right = false


# warning-ignore:unused_argument
func _process(delta):
	facing()
	if previous_state == "Dead":
		state = "Dead"
	match state:
		"Idle":
			idleLoop()
			moveAnimation()
		"Dead":
			deadLoop()
		"Hurt":
			hurtLoop()
		"Pursue":
			pursueLoop()
			moveAnimation()
		"Reviving":
			pass
		


# warning-ignore:unused_argument
func _physics_process(delta):
	if gravity_on:
		gravity()
	
	motion.x += move_direction.x*accel
	
	if motion.x <= 1.5 and motion.x >= -1.5:
		steady = true
	else:
		steady = false
	
	if state != "Hurt":
		motion.x = clamp(motion.x, -maxspeed, maxspeed)
	motion = move_and_slide(motion, Vector2(0, -1), false, 1)
	motion.x = lerp(motion.x, 0, 0.15)
	


func moveAnimation():
	if !attacking and state != "Dead":
		if steady:
			$Hurt.visible = false
			$Dead.visible = false
			$Idle.visible = true
			$Walk.visible = false
			$Attack.visible = false
			$AnimationPlayer.play("Idle")
		else:
			$Hurt.visible = false
			$Dead.visible = false
			$Idle.visible = false
			$Walk.visible = true
			$Attack.visible = false
			$AnimationPlayer.play("Walk")


func gravity():
	motion.y += gravityforce
	if motion.y > maxfallspeed:
		motion.y = maxfallspeed


func facing():
	if motion.x < 0:
		facing_right = false
	elif motion.x > 0:
		facing_right = true
	
	if !facing_right:
		$Hurt.scale.x = -1
		$Idle.scale.x = -1
		$Dead.scale.x = -1
		$Walk.scale.x = -1
		$Attack.scale.x = -1
	else:
		$Hurt.scale.x = 1
		$Idle.scale.x = 1
		$Dead.scale.x = 1
		$Walk.scale.x = 1
		$Attack.scale.x = 1


func idleLoop():
	move_direction.x = 0
	
	$Hurt.visible = false
	$Dead.visible = false
	$Idle.visible = true
	$Walk.visible = false
	$Attack.visible = false
	$AnimationPlayer.play("Idle")
	
	gravity_on = true


func deadLoop():
	gravity_on = false
	move_direction.x = 0


func hurtLoop():
	gravity_on = true
	move_direction.x = 0


func pursueLoop():
	gravity_on = true
	
	if !attacking:
		if get_global_position().distance_to(player.get_global_position()) > 30:
			move_direction.x = (get_global_position().direction_to(player.get_global_position()).x)
		else:
			move_direction.x = 0
			if can_attack:
				attack()

func attack():
	can_attack = false
	attacking = true
	
	$Hurt.visible = false
	$Dead.visible = false
	$Idle.visible = false
	$Walk.visible = false
	$Attack.visible = true
	$AnimationPlayer.play("Attack")
	$"Attack Speed".start()


func hurt(damage, direction):
	currenthealth -= damage
	hpBarUpdate()
	if hp_percentage <= 0:
		die()
	else :
		if !state == "Hurt":
			previous_state = state
			state = "Hurt"
		$Hurt.visible = true
		$Dead.visible = false
		$Idle.visible = false
		$Walk.visible = false
		$Attack.visible = false
		if direction.x == 1:
			$AnimationPlayer.play("Hurt Right")
		elif direction.x == -1:
			$AnimationPlayer.play("Hurt Left")


func hpBarUpdate():
	hp_bar.show()
	hp_percentage = int((float(currenthealth)/maxhealth)*100)
	hp_tween.interpolate_property(hp_bar, 'value', hp_bar.value, hp_percentage, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	hp_tween.start()
	if hp_percentage > 60:
		hp_bar.set_tint_progress("14e114") #Green
	elif hp_percentage <= 60 and hp_percentage > 25:
		hp_bar.set_tint_progress("ffd800") #Yellow
	else:
		hp_bar.set_tint_progress("ff0000") #Red
	hp_timer.start()


func die():
	previous_state = state
	state = "Dead"
	attacking = false
	$Hurt.visible = false
	$Dead.visible = true
	$Idle.visible = false
	$Walk.visible = false
	$Attack.visible = false
	$AnimationPlayer.play("Dead")
	get_node("CollisionShape2D").set_deferred('disabled', true)
	get_node("AttackArea/SkeletonBody").set_deferred('disabled', true)
	get_node("VisionRange/CollisionShape2D").set_deferred('disabled', true)
	$RespawnTime.start()
	hp_bar.hide()


func hurtMovement(direction):
	if direction.x == 1:
		motion.x = 200
		motion.y = -100
		
	elif direction.x == -1:
		motion.x = -200
		motion.y = -100
		
	elif direction.y == -1:
		if direction.x == 1:
			motion.x = 60
			motion.y = -200
		else:
			motion.x = -60
			motion.y = -200
		
	elif direction.y == 1:
		if direction.x == 1:
			motion.x = 60
			motion.y = 200
		else:
			motion.x = -60
			motion.y = 200


func _on_RespawnTime_timeout():
	previous_state = null
	state = "Reviving"
	$Hurt.visible = false
	$Dead.visible = true
	$Idle.visible = false
	$Walk.visible = false
	$Attack.visible = false
	$AnimationPlayer.play_backwards("Dead")
	yield($AnimationPlayer, "animation_finished")
	
	state = "Idle"
	get_node("CollisionShape2D").set_deferred('disabled', false)
	get_node("AttackArea/SkeletonBody").set_deferred('disabled', false)
	get_node("VisionRange/CollisionShape2D").set_deferred('disabled', false)
	
	currenthealth = maxhealth
	hpBarUpdate()
	hp_bar.hide()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		$Hurt.visible = false
		$Dead.visible = false
		$Idle.visible = false
		$Walk.visible = false
		$Attack.visible = false
	if anim_name == "Hurt Right" || anim_name == "Hurt Left":
		attacking = false
		if previous_state == "Pursue":
			previous_state = state
			state = "Pursue"
		else:
			previous_state = state
			state = "Idle"
	if anim_name == "Attack":
		attacking = false


func _on_AttackArea_body_entered(body):
	if body.is_in_group("Players"):
		if body.facing_right == true:
			body.getHurt(attackdamage, Vector2(1, 0))
		else:
			body.getHurt(attackdamage, Vector2(-1, 0))


func _on_Hpbar_timer_timeout():
	hp_bar.hide()


func _on_VisionRange_body_entered(body):
	if state != "Dead":
		if body.is_in_group("Players"):
			player_in_range = true
			previous_state = state
			state = "Pursue"


func _on_VisionRange_body_exited(body):
	if state != "Dead":
		if body.is_in_group("Players"):
			attacking = false
			player_in_range = false
			previous_state = state
			state = "Idle"


func _on_Attack_Speed_timeout():
	can_attack = true

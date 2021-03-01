extends KinematicBody2D

onready var hp_bar = get_node("Hp_bar")
onready var hp_timer = get_node("Hp_bar/Hpbar timer")
onready var hp_tween = get_node("Hp_bar/Tween")

var gravity = 20
var maxfallspeed = 200

var maxhealth = 100
var currenthealth
var hp_percentage
var isdead = false
var hurted =false

var facing_right = true

var motion = Vector2()

var attackdamage = 20


func _ready():
	currenthealth = maxhealth
	hpBarUpdate()
	hp_bar.hide()
	add_to_group("Enemies")


func _physics_process(delta):	
	if !isdead:
		motion.y += gravity
		if motion.y > maxfallspeed:
			motion.y = maxfallspeed
		motion.x = lerp(motion.x, 0, 0.15)
	else:
		motion.x = 0
	
	if !isdead && !hurted:
		$Hurt.visible = false
		$Dead.visible = false
		$Idle.visible = true
		$AnimationPlayer.play("Idle")
	
	motion = move_and_slide(motion, Vector2(0, -1), false, 1)



func hurt(damage, direction):
	currenthealth -= damage
	hpBarUpdate()
	if currenthealth <= 0:
		die()
	else :
		hurted = true
		$Hurt.visible = true
		$Dead.visible = false
		$Idle.visible = false
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
	isdead = true
	get_node("CollisionShape2D").set_deferred('disabled', true)
	get_node("AttackArea/SkeletonBody").set_deferred('disabled', true)
	$Hurt.visible = false
	$Dead.visible = true
	$Idle.visible = false
	$AnimationPlayer.play("Dead")
	$RespawnTime.start()
	hp_bar.hide()



func _on_RespawnTime_timeout():
	if isdead:
		get_node("CollisionShape2D").set_deferred('disabled', false)
		get_node("AttackArea/SkeletonBody").set_deferred('disabled', false)
		isdead = false
		hurted = false
		
		currenthealth = maxhealth
		hpBarUpdate()
		hp_bar.hide()



func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dead":
		$Hurt.visible = false
		$Dead.visible = false
		$Idle.visible = false
	if anim_name == "Hurt Right" || anim_name == "Hurt Left":
		hurted = false
		



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



func _on_AttackArea_body_entered(body):
	if body.is_in_group("Players"):
		if body.facing_right == true:
			body.getHurt(attackdamage, Vector2(1, 0))
		else:
			body.getHurt(attackdamage, Vector2(-1, 0))


func _on_Hpbar_timer_timeout():
	hp_bar.hide()

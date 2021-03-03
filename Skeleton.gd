extends KinematicBody2D

onready var hp_bar = get_node("Hp_bar")
onready var hp_timer = get_node("Hp_bar/Hpbar timer")
onready var hp_tween = get_node("Hp_bar/Tween")
onready var player = get_parent().get_node("Character")
onready var navigation_map = get_parent().get_node("TileSet/Navigation2D")

var rng = RandomNumberGenerator.new()

var gravity = 20
var maxfallspeed = 200
var accel = 10
var maxspeed = 60

var maxhealth = 100
var currenthealth
var hp_percentage
var state = "Idle"

var facing_right
var destination

var motion = Vector2()

var can_attack = true
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

func _process(delta):
	
	match state:
		"Idle":
			idleLoop()
		"Dead":
			deadLoop()
		"Hurt":
			hurtLoop()
		"Pursue":
			pursueLoop()
		

func _physics_process(delta):
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
	motion = move_and_slide(motion, Vector2(0, -1), false, 1)


func idleLoop():
	$Hurt.visible = false
	$Dead.visible = false
	$Idle.visible = true
	$Walk.visible = false
	$Attack.visible = false
	$AnimationPlayer.play("Idle")
	
	motion.y += gravity
	if motion.y > maxfallspeed:
		motion.y = maxfallspeed
		
	motion.x = lerp(motion.x, 0, 0.15)
	
	print(get_global_position().direction_to(player.get_global_position()).x)


func deadLoop():
	motion.x = 0
	motion.y = 0
	
	$Hurt.visible = false
	$Dead.visible = true
	$Idle.visible = false
	$Walk.visible = false
	$Attack.visible = false
	$AnimationPlayer.play("Dead")


func hurtLoop():
	motion.y += gravity
	if motion.y > maxfallspeed:
		motion.y = maxfallspeed
	
	motion.x = lerp(motion.x, 0, 0.15)


func attack():
	can_attack = false
	motion.x = 0
	
	$Hurt.visible = false
	$Dead.visible = false
	$Idle.visible = false
	$Walk.visible = false
	$Attack.visible = true
	$AnimationPlayer.play("Attack")
	$"Attack Speed".start()

func pursueLoop():
	motion.y += gravity
	if motion.y > maxfallspeed:
		motion.y = maxfallspeed
	
	if $AnimationPlayer.current_animation != "Attack":
		$Hurt.visible = false
		$Dead.visible = false
		$Idle.visible = false
		$Walk.visible = true
		$Attack.visible = false
		$AnimationPlayer.play("Walk")
		if get_global_position().distance_to(player.get_global_position()) > 30:
			motion.x += (get_global_position().direction_to(player.get_global_position()).x)*accel
			motion.x = clamp(motion.x, -maxspeed, maxspeed)
			if motion.x < 0:
				facing_right = false
			else:
				facing_right = true
		else:
			if can_attack == true:
				attack()
	
	motion.x = lerp(motion.x, 0, 0.15)


func hurt(damage, direction):
	currenthealth -= damage
	hpBarUpdate()
	if currenthealth <= 0:
		die()
	else :
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
	state = "Dead"
	get_node("CollisionShape2D").set_deferred('disabled', true)
	get_node("AttackArea/SkeletonBody").set_deferred('disabled', true)
	get_node("VisionRange/CollisionShape2D").set_deferred('disabled', true)
	$RespawnTime.start()
	hp_bar.hide()



func _on_RespawnTime_timeout():
	get_node("CollisionShape2D").set_deferred('disabled', false)
	get_node("AttackArea/SkeletonBody").set_deferred('disabled', false)
	get_node("VisionRange/CollisionShape2D").set_deferred('disabled', false)
	state = "Idle"
	
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
		state = "Idle"
		



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


func _on_VisionRange_body_entered(body):
	if body.is_in_group("Players"):
		player_in_range = true
		state = "Pursue"


func _on_VisionRange_body_exited(body):
	if body.is_in_group("Players"):
		player_in_range = false
		state = "Idle"


func _on_Attack_Speed_timeout():
	can_attack = true

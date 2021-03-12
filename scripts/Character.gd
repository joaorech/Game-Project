extends KinematicBody2D

onready var hp_bar = get_parent().get_node("GUI/CharacterHud/Hp_bar")
onready var hp_timer = get_parent().get_node("GUI/CharacterHud/Hp_bar/Hp_bar_timer")
onready var hp_tween = get_parent().get_node("GUI/CharacterHud/Hp_bar/Tween")

onready var energy_bar = get_parent().get_node("GUI/CharacterHud/Energy_bar")
onready var energy_timer = get_parent().get_node("GUI/CharacterHud/Energy_bar/Energy_bar_timer")
onready var energy_tween = get_parent().get_node("GUI/CharacterHud/Energy_bar/Tween")

onready var mana_bar = get_parent().get_node("GUI/CharacterHud/Mana_bar")
onready var mana_timer = get_parent().get_node("GUI/CharacterHud/Mana_bar/Mana_bar_timer")
onready var mana_tween = get_parent().get_node("GUI/CharacterHud/Mana_bar/Tween")

onready var gui = get_parent().get_node("GUI")


var up = Vector2(0, -1)
var gravity = 20
var maxfallspeed = 300
var maxspeed = 100
var attackdashspeed = 400
var dashspeed = 1200
var accel = 10
var jumpforce = 390

var motion = Vector2()
var facing_right = true

var attacking = false
var attackcombo = 1
var attackdamage = 40

var maxhealth = 100
var currenthealth
var hp_percentage
var hurted = false
var dead = false

var maxenergy = 100
var currentenergy
var energy_percentage

var maxmana = 100
var currentmana
var mana_percentage

var dashing = false




func _ready():
	add_to_group("Players")
	
	currenthealth = maxhealth
	hpBarUpdate()
	
	currentenergy = maxenergy
	energyBarUpdate()
	
	currentmana = maxmana
	manaBarUpdate()


func _process(delta):
	if Input.is_action_just_pressed("Game Menu"):
		gui.game_menu_on = true
	if dead:
		get_parent().get_tree().change_scene("res://scenes/World.tscn")


# warning-ignore:unused_argument
func _physics_process(delta):
	
	if !facing_right:
		$Sprite.scale.x = -1
	else:
		$Sprite.scale.x = 1
	
	if !gui.game_menu_on:
		motion.y += gravity
		if motion.y > maxfallspeed:
			motion.y = maxfallspeed
		
		if !attacking && !hurted && !dashing:
			motion.x = clamp(motion.x, -maxspeed, maxspeed)
		else:
			motion.x = clamp(motion.x, -dashspeed, dashspeed)
		
		
		if Input.is_action_pressed("Right") && !attacking && !hurted && !dashing:
			motion.x += accel
			facing_right = true
			$AnimationPlayer.play("Walk")
		elif Input.is_action_pressed("Left") && !attacking && !hurted && !dashing:
			motion.x -= accel
			facing_right = false
			$AnimationPlayer.play("Walk")
		elif !attacking && !hurted && !dashing:
			motion.x = lerp(motion.x, 0, 0.15)
			$AnimationPlayer.play("Idle")
		else:
			motion.x = lerp(motion.x, 0, 0.3)
		
		if is_on_floor():
			if Input.is_action_just_pressed("Jump") && !attacking && !hurted:
				motion.y = -jumpforce
				motion.x = lerp(motion.x, 0, 0.2)
		
		if !is_on_floor() && !attacking && !hurted && !dashing:
			if motion.y > 1:
				$AnimationPlayer.play("Fall")
			elif motion.y < 0:
				$AnimationPlayer.play("Jump")
		
		if Input.is_action_just_pressed("Attack") && attackcombo == 1 && !hurted && !dashing:
			attacking = true
			$AnimationPlayer.play("Attack")
			attackcombo += 1
		elif Input.is_action_just_pressed("Attack") && attackcombo == 2 && !hurted && !dashing:
			attacking = true
			$AnimationPlayer.queue("Attack 2")
			attackcombo += 1
		elif Input.is_action_just_pressed("Attack") && attackcombo == 3 && !hurted && !dashing:
			attacking = true
			$AnimationPlayer.queue("Attack 3")
			attackcombo = 0
		
		if Input.is_action_just_pressed("Dash Forward") && !hurted && !attacking:
			dashing = true
			$AnimationPlayer.play("Dash Forward")
		
		motion = move_and_slide(motion, up)



func AttackMovement():
	if facing_right:
		motion.x = attackdashspeed
	else :
		motion.x = -attackdashspeed
	



func frontDashMovement():
	if facing_right:
		motion.x = dashspeed
	else :
		motion.x = -dashspeed
	



func backDashMovement():
	if facing_right:
		motion.x = -dashspeed
	else :
		motion.x = dashspeed
	



func HurtMovement(direction):
	if direction.x == 1:
		motion.x = 400
		motion.y = -120
		
	elif direction.x == -1:
		motion.x = -400
		motion.y = -120
	



func getHurt(damage, direction):
	currenthealth -= damage
	currenthealth = clamp(currenthealth, 0, maxhealth)
	hpBarUpdate()
	if currenthealth <= 0:
		dead = true
	else:
		hurted = true
		if direction.x == 1:
			$AnimationPlayer.play("Hurt Right")
		elif direction.x == -1:
			$AnimationPlayer.play("Hurt Left")



func hpBarUpdate():
	hp_bar.show()
	hp_percentage = int((float(currenthealth)/maxhealth)*100)
	hp_tween.interpolate_property(hp_bar, 'value', hp_bar.value, hp_percentage, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	hp_tween.start()
	hp_timer.start()



func energyBarUpdate():
	energy_bar.show()
	energy_percentage = int((float(currentenergy)/maxenergy)*100)
	energy_tween.interpolate_property(energy_bar, 'value', energy_bar.value, energy_percentage, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	energy_tween.start()
	energy_timer.start()



func manaBarUpdate():
	mana_bar.show()
	mana_percentage = int((float(currentmana)/maxmana)*100)
	mana_tween.interpolate_property(mana_bar, 'value', mana_bar.value, mana_percentage, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	mana_tween.start()
	mana_timer.start()



func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Attack End":
		attacking = false
		attackcombo = 1
	
	if anim_name == "Attack":
		$AnimationPlayer.play("Attack End")
	
	if anim_name == "Attack 2":
		$AnimationPlayer.play("Attack End")
	
	if anim_name == "Attack 3":
		$AnimationPlayer.play("Attack End")
	
	if anim_name == "Hurt Right" || anim_name == "Hurt Left":
		attacking = false
		dashing = false
		hurted = false
		attackcombo = 1
	
	if anim_name == "Dash Forward":
		dashing = false



func _on_AttackArea_body_entered(body):
	if body.is_in_group("Enemies"):
		if facing_right:
			body.hurt(attackdamage, Vector2(1,0))
		else:
			body.hurt(attackdamage, Vector2(-1,0))



func _on_Hp_bar_timer_timeout():
	hp_bar.hide()

func _on_Hp_regen_timeout():
	if hp_percentage != 100:
		currenthealth += 1
		hpBarUpdate()



func _on_Energy_bar_timer_timeout():
	energy_bar.hide()

func _on_Energy_regen_timeout():
	if energy_percentage != 100:
		currentenergy += 15
		energyBarUpdate()



func _on_Mana_bar_timer_timeout():
	mana_bar.hide()

func _on_Mana_regen_timeout():
	if mana_percentage != 100:
		currentmana += 1
		manaBarUpdate()

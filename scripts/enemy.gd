class_name FrontierEnemy
extends CharacterBody2D

signal defeated(enemy: FrontierEnemy)
var home_x := 0.0
var direction := 1.0
var health := 45
var target: FrontierPlayer
var hit_flash := 0.0
var attack_timer := 0.0

func _ready() -> void:
	home_x = global_position.x
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 17
	shape.height = 42
	cs.shape = shape
	add_child(cs)

func _physics_process(delta: float) -> void:
	hit_flash = maxf(0, hit_flash-delta)
	attack_timer = maxf(0, attack_timer-delta)
	if not is_on_floor(): velocity.y += 1500.0 * delta
	if target and global_position.distance_to(target.global_position) < 330:
		direction = signf(target.global_position.x-global_position.x)
		velocity.x = direction * 105.0
		if global_position.distance_to(target.global_position) < 44 and attack_timer <= 0:
			target.take_damage(14)
			attack_timer = 0.9
	else:
		if absf(global_position.x-home_x) > 150: direction = -signf(global_position.x-home_x)
		velocity.x = direction * 55.0
	move_and_slide()
	queue_redraw()

func hurt(amount: int, push: float) -> void:
	health -= amount
	velocity.x = push
	hit_flash = 0.12
	if health <= 0:
		defeated.emit(self)
		queue_free()

func _draw() -> void:
	var c := Color.WHITE if hit_flash > 0 else Color("#b83f4c")
	draw_circle(Vector2.ZERO, 19, Color("#17202b"))
	draw_rect(Rect2(-17,-13,34,27), c, true)
	draw_circle(Vector2(7*direction,-4), 4, Color("#ffd166"))
	draw_line(Vector2(-12,16), Vector2(-17,25), Color("#17202b"), 5)
	draw_line(Vector2(12,16), Vector2(17,25), Color("#17202b"), 5)

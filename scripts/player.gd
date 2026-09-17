class_name FrontierPlayer
extends CharacterBody2D

signal stats_changed
signal died
signal attack_requested(kind: String, origin: Vector2, facing: float)

const SPEED := 310.0
const JUMP_SPEED := -620.0
const GRAVITY := 1650.0
var max_health := 100
var health := 100
var level := 1
var xp := 0
var xp_next := 100
var scrap := 0
var potions := 1
var weapon := "Blade"
var has_pistol := false
var facing := 1.0
var attack_cooldown := 0.0
var invulnerable := 0.0
var respawn_point := Vector2(180, 470)

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 16
	capsule.height = 52
	shape.shape = capsule
	add_child(shape)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	if not is_on_floor(): velocity.y += GRAVITY * delta
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, axis * SPEED, 1800.0 * delta)
	if axis != 0: facing = signf(axis)
	if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = JUMP_SPEED
	if Input.is_action_just_pressed("weapon_1"): weapon = "Blade"; stats_changed.emit()
	if Input.is_action_just_pressed("weapon_2") and has_pistol: weapon = "Pistol"; stats_changed.emit()
	if Input.is_action_just_pressed("use_item"): use_potion()
	if Input.is_action_pressed("attack") and attack_cooldown <= 0:
		attack_cooldown = 0.38 if weapon == "Blade" else 0.28
		attack_requested.emit(weapon, global_position + Vector2(facing * 28, -4), facing)
	move_and_slide()
	if global_position.y > 900: take_damage(999)
	queue_redraw()

func take_damage(amount: int) -> void:
	if invulnerable > 0: return
	health -= amount
	invulnerable = 0.65
	stats_changed.emit()
	if health <= 0:
		health = max_health
		global_position = respawn_point
		velocity = Vector2.ZERO
		died.emit()
		stats_changed.emit()

func use_potion() -> void:
	if potions > 0 and health < max_health:
		potions -= 1
		health = mini(max_health, health + 45)
		stats_changed.emit()

func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = int(xp_next * 1.35)
		max_health += 15
		health = max_health
	stats_changed.emit()

func _draw() -> void:
	if invulnerable > 0 and int(invulnerable * 12.0) % 2 == 0: return
	draw_polygon(PackedVector2Array([Vector2(-10,-12), Vector2(-30*facing,-5), Vector2(-13,1)]), PackedColorArray([Color("#e15d44")]))
	draw_rect(Rect2(-15,-13,30,38), Color("#25384a"), true)
	draw_circle(Vector2(0,-24), 14, Color("#f1c7a5"))
	draw_rect(Rect2(-16,-36,32,10), Color("#17222d"), true)
	draw_circle(Vector2(5*facing,-24), 2.5, Color("#111827"))
	if weapon == "Blade": draw_line(Vector2(13*facing,0), Vector2(30*facing,-16), Color("#dce8ef"), 5)
	else: draw_rect(Rect2(10*facing if facing > 0 else -30,-6,20,7), Color("#e1a94b"), true)

extends Node2D

const PlayerType = preload("res://scripts/player.gd")
const EnemyType = preload("res://scripts/enemy.gd")
const EnvironmentType = preload("res://scripts/environment.gd")
const PlatformVisualType = preload("res://scripts/platform_visual.gd")
var player: FrontierPlayer
var environment: FrontierEnvironment
var stats_label: Label
var quest_label: Label
var toast_label: Label
var toast_time := 0.0
var mission := 0
var defeated_count := 0
var quest_giver := Vector2(420, 505)
var beacon := Vector2(3580, 410)
var pickups: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var world_time := 0.0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#0b1422"))
	environment = EnvironmentType.new()
	add_child(environment)
	build_world()
	player = PlayerType.new()
	player.position = Vector2(180, 470)
	add_child(player)
	environment.set_focus(player)
	player.attack_requested.connect(_on_attack)
	player.stats_changed.connect(update_hud)
	player.died.connect(func(): show_toast("You fell. Returned to the last camp."))
	for node in get_tree().get_nodes_in_group("enemy"): node.target = player
	make_camera()
	make_hud()
	update_hud()
	show_toast("Find Warden Mira at the frontier camp")

func build_world() -> void:
	make_platform(Vector2(500,570), Vector2(1000,90), "grass")
	make_platform(Vector2(1450,610), Vector2(700,80), "stone")
	make_platform(Vector2(2300,560), Vector2(900,110), "rust")
	make_platform(Vector2(3400,590), Vector2(1200,90), "crystal")
	for p in [[800,430,190,24],[1120,500,190,24],[1540,440,220,24],[1850,350,180,24],[2140,450,190,24],[2660,390,210,24],[3000,480,180,24],[3350,370,210,24],[3700,470,220,24]]:
		var region_style := "grass" if p[0] < 1300 else ("stone" if p[0] < 2100 else ("rust" if p[0] < 3000 else "crystal"))
		make_platform(Vector2(p[0],p[1]), Vector2(p[2],p[3]), region_style)
	for x in [1040,1710,2050,2520,2870,3200]: spawn_enemy(Vector2(x,470 if x < 2100 else 430))
	spawn_pickup(Vector2(780,385),"Scrap")
	spawn_pickup(Vector2(1130,455),"Scrap")
	spawn_pickup(Vector2(1550,395),"Scrap")
	spawn_pickup(Vector2(1880,305),"Potion")
	spawn_pickup(Vector2(2690,345),"Scrap")

func make_platform(pos: Vector2, size: Vector2, style: String, texture: Texture2D = null) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	var visual := PlatformVisualType.new()
	visual.setup(size, style, texture)
	body.add_child(visual)

func spawn_enemy(pos: Vector2) -> void:
	var enemy := EnemyType.new()
	enemy.position = pos
	enemy.add_to_group("enemy")
	enemy.defeated.connect(_enemy_defeated)
	add_child(enemy)

func spawn_pickup(pos: Vector2, kind: String) -> void:
	pickups.append({"pos":pos,"kind":kind,"taken":false,"phase":randf()*6.0})

func make_camera() -> void:
	var camera := Camera2D.new()
	camera.position = Vector2(180,-80)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_right = 4000
	camera.limit_top = 0
	camera.limit_bottom = 720
	player.add_child(camera)

func make_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var shade := ColorRect.new()
	shade.position=Vector2(18,18); shade.size=Vector2(375,112); shade.color=Color(0.025,0.055,0.09,0.9)
	hud.add_child(shade)
	stats_label=Label.new(); stats_label.position=Vector2(35,30); stats_label.add_theme_font_size_override("font_size",20); hud.add_child(stats_label)
	quest_label=Label.new(); quest_label.position=Vector2(820,24); quest_label.size=Vector2(430,120); quest_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; quest_label.add_theme_font_size_override("font_size",19); quest_label.add_theme_color_override("font_color",Color("#ffd166")); hud.add_child(quest_label)
	toast_label=Label.new(); toast_label.position=Vector2(300,590); toast_label.size=Vector2(680,60); toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; toast_label.add_theme_font_size_override("font_size",24); toast_label.add_theme_color_override("font_color",Color("#fff1c7")); hud.add_child(toast_label)
	var help:=Label.new(); help.position=Vector2(18,670); help.text="A/D Move   SPACE Jump   LMB/J Attack   E Interact   1/2 Weapons   Q Potion"; help.add_theme_font_size_override("font_size",16); help.add_theme_color_override("font_color",Color("#a9bdc8")); hud.add_child(help)

func _process(delta: float) -> void:
	world_time += delta
	toast_time = maxf(0,toast_time-delta)
	if toast_time <= 0 and toast_label: toast_label.text = ""
	check_pickups()
	update_projectiles(delta)
	if player and Input.is_action_just_pressed("interact"):
		if player.global_position.distance_to(quest_giver)<100: talk_to_mira()
		elif mission==3 and player.global_position.distance_to(beacon)<120: complete_beacon()
	queue_redraw()

func check_pickups() -> void:
	for item in pickups:
		if not item.taken and player.global_position.distance_to(item.pos)<42:
			item.taken=true
			if item.kind=="Scrap":
				player.scrap+=1
				show_toast("Salvage collected (%d/3)" % mini(player.scrap,3))
				if mission==1 and player.scrap>=3: show_toast("Salvage complete — return to Mira")
			else:
				player.potions+=1
				show_toast("Health tonic acquired")
			player.stats_changed.emit()

func talk_to_mira() -> void:
	match mission:
		0: mission=1; show_toast("Mission accepted: Scavenger's Due")
		1:
			if player.scrap>=3:
				player.has_pistol=true; player.weapon="Pistol"; player.add_xp(60)
				if defeated_count >= 3:
					mission=3
					show_toast("REWARD: Rustlock pistol — the pass is already clear!")
				else:
					mission=2
					show_toast("REWARD: Rustlock pistol — clear 3 raiders")
			else: show_toast("Mira: Bring me 3 pieces of salvage.")
		2: show_toast("Mira: Raiders hold the eastern pass. Defeat 3.")
		3: show_toast("Mira: Reach the old beacon and press E.")
		4: show_toast("Mira: The frontier is open. Explore and grow stronger.")
	update_hud()

func complete_beacon() -> void:
	mission=4
	player.add_xp(120)
	player.respawn_point=Vector2(3580,410)
	player.potions+=2
	show_toast("FRONTIER RESTORED — free roam unlocked!")
	update_hud()

func _enemy_defeated(_enemy: FrontierEnemy) -> void:
	defeated_count+=1
	player.add_xp(35)
	if randf()<0.35: player.potions+=1
	if mission==2 and defeated_count>=3:
		mission=3
		show_toast("Pass secured — reach the ancient beacon")
	else: show_toast("Raider defeated  +35 XP")
	update_hud()

func _on_attack(kind: String, origin: Vector2, facing: float) -> void:
	if kind=="Blade":
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy) and origin.distance_to(enemy.global_position)<65 and signf(enemy.global_position.x-player.global_position.x)==facing:
				enemy.hurt(28+player.level*2,facing*320)
	else: projectiles.append({"pos":origin,"vel":Vector2(facing*760,0),"life":1.1})

func update_projectiles(delta: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var bullet=projectiles[i]
		bullet.pos+=bullet.vel*delta
		bullet.life-=delta
		var hit=false
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy) and bullet.pos.distance_to(enemy.global_position)<26:
				enemy.hurt(20+player.level*2,bullet.vel.x*0.25)
				hit=true
				break
		if hit or bullet.life<=0: projectiles.remove_at(i)
		else: projectiles[i]=bullet

func update_hud() -> void:
	if not stats_label: return
	stats_label.text="HP  %d / %d     LEVEL %d\nXP  %d / %d     TONICS %d\nWEAPON  %s%s" % [player.health,player.max_health,player.level,player.xp,player.xp_next,player.potions,player.weapon,"  • Ammo ∞" if player.weapon=="Pistol" else ""]
	var quests=["Talk to Warden Mira  [E]","SCAVENGER'S DUE\nCollect salvage: %d / 3"%mini(player.scrap,3),"CLEAR THE PASS\nRaiders defeated: %d / 3"%mini(defeated_count,3),"LIGHT IN THE WASTE\nReach the eastern beacon", "FRONTIER RESTORED\nFree roam • Level up • Explore"]
	quest_label.text=quests[mission]

func show_toast(text: String) -> void:
	if toast_label:
		toast_label.text=text
		toast_time=3.2

func _draw() -> void:
	draw_circle(quest_giver+Vector2(0,-21),15,Color("#d9aa84"))
	draw_rect(Rect2(quest_giver+Vector2(-16,-6),Vector2(32,42)),Color("#386080"),true)
	draw_string(ThemeDB.fallback_font,quest_giver+Vector2(-58,-58),"WARDEN MIRA",HORIZONTAL_ALIGNMENT_LEFT,120,16,Color("#d8e6ed"))
	draw_string(ThemeDB.fallback_font,Vector2(170,185),"GREENFALL CAMP",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#718f84"))
	draw_string(ThemeDB.fallback_font,Vector2(1760,185),"THE RUSTED PASS",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#9b7460"))
	draw_string(ThemeDB.fallback_font,Vector2(3150,185),"NIGHTGLASS RIDGE",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#776c91"))
	var glow=30+sin(world_time*3)*7
	draw_circle(beacon,glow,Color(0.3,0.8,1.0,0.15)); draw_line(beacon+Vector2(0,80),beacon-Vector2(0,75),Color("#77d9f7"),8); draw_circle(beacon-Vector2(0,78),13,Color("#c9f4ff"))
	for item in pickups:
		if not item.taken:
			var pos:Vector2=item.pos+Vector2(0,sin(world_time*3+item.phase)*5)
			var color=Color("#e9b44c") if item.kind=="Scrap" else Color("#6ee7a8")
			draw_circle(pos,10,color); draw_circle(pos,16,Color(color,0.15),false,3)
	for bullet in projectiles:
		draw_circle(bullet.pos,5,Color("#ffd166"))
		draw_line(bullet.pos,bullet.pos-Vector2(signf(bullet.vel.x)*18,0),Color("#f6b84a"),3)

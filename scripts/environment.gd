class_name FrontierEnvironment
extends Node2D

const IMAGE_EXTENSIONS := ["png", "webp", "jpg", "jpeg", "svg"]
const CLOUD_FOLDER := "res://assets/environment/clouds"
const BUILDING_FOLDER := "res://assets/environment/buildings"

var focus: Node2D
var time := 0.0
var cloud_textures: Array[Texture2D] = []
var building_textures: Array[Texture2D] = []
var cloud_sprites: Array[Sprite2D] = []
var building_sprites: Array[Sprite2D] = []
var cloud_cleanup_material: ShaderMaterial

func _ready() -> void:
	z_index = -50
	cloud_textures = load_folder_textures(CLOUD_FOLDER)
	building_textures = load_folder_textures(BUILDING_FOLDER)
	cloud_cleanup_material = make_cloud_cleanup_material()
	make_gradient_sky()
	make_optional_sprites()
	queue_redraw()

func set_focus(node: Node2D) -> void:
	focus = node

func load_folder_textures(folder: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var directory := DirAccess.open(folder)
	if directory == null: return textures
	for file_name in directory.get_files():
		var extension := file_name.get_extension().to_lower()
		if extension in IMAGE_EXTENSIONS:
			var resource := load(folder.path_join(file_name)) as Texture2D
			if resource: textures.append(resource)
	return textures

func make_cloud_cleanup_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float erosion_pixels = 4.0;
uniform float fringe_strength = 0.95;

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float brightness = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	vec2 px = TEXTURE_PIXEL_SIZE * erosion_pixels;
	float neighbors = 0.0;
	neighbors += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	neighbors += texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	neighbors += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	neighbors += texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	neighbors += texture(TEXTURE, UV + px).a;
	neighbors += texture(TEXTURE, UV - px).a;
	neighbors += texture(TEXTURE, UV + vec2(px.x, -px.y)).a;
	neighbors += texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
	float coverage = neighbors / 8.0;
	// Erase isolated flecks and pull the silhouette inward past the dirty rim.
	float connected = smoothstep(0.34, 0.72, coverage);
	float edge = 1.0 - smoothstep(0.70, 0.96, coverage);
	// The supplied cloud sheets contain bright cyan and blue matte contamination.
	float blue_cyan_fringe = smoothstep(0.16, 0.42, max(pixel.g, pixel.b) - pixel.r);
	float color_range = max(pixel.r, max(pixel.g, pixel.b)) - min(pixel.r, min(pixel.g, pixel.b));
	float neon_artifact = smoothstep(0.52, 0.78, color_range) * blue_cyan_fringe;
	float fringe_keep = (1.0 - blue_cyan_fringe * edge * fringe_strength) * (1.0 - neon_artifact * 0.98);
	float dark_keep = smoothstep(0.08, 0.24, brightness);
	float clean_alpha = pixel.a * connected * fringe_keep * dark_keep;
	vec3 clean_color = mix(pixel.rgb, vec3(0.94, 0.98, 1.0), blue_cyan_fringe * edge * 0.75);
	COLOR = vec4(clean_color, clean_alpha) * COLOR;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func make_gradient_sky() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = -100
	add_child(canvas)
	var sky := TextureRect.new()
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture := GradientTexture2D.new()
	texture.width = 1280
	texture.height = 720
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
	gradient.colors = PackedColorArray([Color("#64b5e8"), Color("#a9daf1"), Color("#f6ddb5")])
	texture.gradient = gradient
	sky.texture = texture
	canvas.add_child(sky)

func make_optional_sprites() -> void:
	if not cloud_textures.is_empty():
		for i in range(10):
			var sprite := Sprite2D.new()
			sprite.texture = cloud_textures[i % cloud_textures.size()]
			sprite.position = Vector2(180 + i * 430, 90 + (i % 3) * 55)
			sprite.modulate = Color(1.0, 1.0, 1.0, 0.46)
			sprite.material = cloud_cleanup_material
			sprite.scale = Vector2.ONE * (0.75 + (i % 4) * 0.18)
			sprite.z_index = -40
			sprite.set_meta("base_x", sprite.position.x)
			sprite.set_meta("speed", 4.0 + i % 3)
			add_child(sprite)
			cloud_sprites.append(sprite)
	if not building_textures.is_empty():
		var cursor_x := -80.0
		for i in range(42):
			var sprite := Sprite2D.new()
			sprite.texture = building_textures[i % building_textures.size()]
			var scale_amount := 0.72 + (i * 7 % 5) * 0.135
			var image_size := sprite.texture.get_size()
			# Every image rests on the same skyline baseline regardless of its dimensions.
			sprite.position = Vector2(cursor_x + image_size.x * scale_amount * 0.5, 535.0 - image_size.y * scale_amount * 0.5)
			var depth_speed := 0.20 if scale_amount < 0.99 else 0.16
			# Distant structures lose warm color in daytime atmospheric perspective.
			sprite.modulate = Color.WHITE if depth_speed > 0.18 else Color(0.62,0.78,0.96,0.92)
			sprite.scale = Vector2.ONE * scale_amount
			# Smaller buildings render later, forming a packed foreground row.
			sprite.z_index = -18 if scale_amount < 0.99 else -23
			sprite.set_meta("base_position", sprite.position)
			sprite.set_meta("parallax_speed", depth_speed)
			add_child(sprite)
			building_sprites.append(sprite)
			cursor_x += maxf(68.0, image_size.x * scale_amount * 0.27)

func _process(delta: float) -> void:
	time += delta
	var active_camera := get_viewport().get_camera_2d()
	var camera_x := active_camera.get_screen_center_position().x if active_camera else (focus.global_position.x if focus else 0.0)
	for i in range(cloud_sprites.size()):
		var base_x: float = cloud_sprites[i].get_meta("base_x")
		var speed: float = cloud_sprites[i].get_meta("speed")
		# A 0.08 scroll factor keeps clouds at the deepest visible layer.
		cloud_sprites[i].position.x = fposmod(base_x + time * speed, 4600.0) - 250.0 + camera_x * 0.92
	for sprite in building_sprites:
		var base_position: Vector2 = sprite.get_meta("base_position")
		var scroll_speed: float = sprite.get_meta("parallax_speed")
		sprite.position = base_position + Vector2(camera_x * (1.0-scroll_speed),0)
	queue_redraw()

func _draw() -> void:
	var active_camera := get_viewport().get_camera_2d()
	var camera_x := active_camera.get_screen_center_position().x if active_camera else (focus.global_position.x if focus else 0.0)
	if cloud_textures.is_empty():
		var cloud_offset := camera_x * 0.92
		for i in range(13):
			var x := fposmod(i * 350.0 + time * (4.0 + i % 3), 4600.0) - 250.0 + cloud_offset
			var y := 80.0 + (i % 4) * 42.0
			var cloud_color := Color(1.0,1.0,1.0,0.23)
			draw_circle(Vector2(x,y),51,cloud_color)
			draw_circle(Vector2(x+57,y-12),70,cloud_color)
			draw_circle(Vector2(x+120,y+5),45,cloud_color)
	if building_textures.is_empty():
		var far_offset := camera_x * 0.84
		var near_offset := camera_x * 0.80
		# Tall, muted structures sit behind the denser foreground row.
		for i in range(31):
			var x := -150.0 + i * 145.0 + far_offset
			var height := 217.5 + (i * 70 % 173)
			var width := 232.5 + (i * 47 % 90)
			draw_rect(Rect2(x,535-height,width,height),Color("#527497"),true)
			var window_pos := Vector2(x+width*0.34+9,525-height)
			draw_rect(Rect2(window_pos-Vector2(9,10),Vector2(18,20)),Color("#7192ae"),true)
		# Short buildings overlap the back row and each other while sharing y=535.
		for i in range(54):
			var x := -220.0 + i * 84.0 + near_offset
			var height := 97.5 + (i * 56 % 120)
			var width := 225.0 + (i * 29 % 68)
			draw_rect(Rect2(x,535-height,width,height),Color("#243b4b"),true)
			var window_pos := Vector2(x+26,541-height)
			draw_rect(Rect2(window_pos-Vector2(8,10),Vector2(16,20)),Color("#2a414e"),true)

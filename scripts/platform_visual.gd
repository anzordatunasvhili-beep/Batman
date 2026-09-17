class_name PlatformVisual
extends Node2D

var platform_size := Vector2(300, 60)
var style := "grass"
var custom_texture: Texture2D

func setup(size: Vector2, surface_style: String, texture: Texture2D = null) -> void:
	platform_size = size
	style = surface_style
	custom_texture = texture
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(-platform_size / 2.0, platform_size)
	if custom_texture:
		draw_texture_rect(custom_texture, rect, true)
		draw_line(Vector2(rect.position.x,rect.position.y),Vector2(rect.end.x,rect.position.y),Color.WHITE,4)
		return
	var base := Color("#3b4b43")
	var top := Color("#71916f")
	if style == "stone": base=Color("#4a4e57"); top=Color("#7d818b")
	elif style == "rust": base=Color("#573e36"); top=Color("#a06046")
	elif style == "crystal": base=Color("#413b55"); top=Color("#8879ad")
	draw_rect(rect,base,true)
	draw_rect(Rect2(rect.position,Vector2(platform_size.x,8)),top,true)
	var cell := 42.0
	for x in range(int(rect.position.x),int(rect.end.x),int(cell)):
		if style == "grass":
			draw_line(Vector2(x,rect.position.y+7),Vector2(x+8,rect.position.y-5-(abs(x)%9)),top.lightened(0.2),2)
		elif style == "stone":
			draw_line(Vector2(x,rect.position.y+10),Vector2(x+22,rect.position.y+22),base.lightened(0.13),2)
		elif style == "rust":
			draw_circle(Vector2(x+15,rect.position.y+20),3,top.darkened(0.25))
		else:
			draw_polygon(PackedVector2Array([Vector2(x+8,rect.position.y+8),Vector2(x+18,rect.position.y+30),Vector2(x+28,rect.position.y+8)]),PackedColorArray([top.darkened(0.18)]))


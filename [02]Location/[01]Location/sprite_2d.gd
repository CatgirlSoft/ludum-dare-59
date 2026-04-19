extends Sprite2D

var position_x = 0
var position_y = 0
var vertical_speed:  float  = 30
var horizontal_speed:  float  = 20

func _process(delta: float) -> void:
	position_x += vertical_speed * delta
	position_y += horizontal_speed * delta
	
	region_rect = Rect2(position_x,position_y,960,540)
	

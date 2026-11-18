extends Control
class_name TouchControls
# Mitad izquierda: joystick flotante. Mitad derecha: mirar (arrastrar).

const RADIUS := 110.0

var move_vector := Vector2.ZERO
var look_delta := Vector2.ZERO

var _move_touch := -1
var _look_touch := -1
var _origin := Vector2.ZERO
var _pos := Vector2.ZERO

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
    var half := get_viewport_rect().size.x * 0.5
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < half and _move_touch == -1:
                _move_touch = event.index
                _origin = event.position
                _pos = event.position
            elif event.position.x >= half and _look_touch == -1:
                _look_touch = event.index
        else:
            if event.index == _move_touch:
                _move_touch = -1
                move_vector = Vector2.ZERO
            elif event.index == _look_touch:
                _look_touch = -1
        queue_redraw()
    elif event is InputEventScreenDrag:
        if event.index == _move_touch:
            _pos = event.position
            move_vector = ((_pos - _origin) / RADIUS).limit_length(1.0)
        elif event.index == _look_touch:
            look_delta += event.relative
        queue_redraw()

func consume_look() -> Vector2:
    var d := look_delta
    look_delta = Vector2.ZERO
    return d

func _draw() -> void:
    if _move_touch != -1:
        draw_arc(_origin, RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.25), 3.0)
        draw_circle(_origin + (_pos - _origin).limit_length(RADIUS), 36.0, Color(1, 1, 1, 0.35))

extends Node3D
# Paso 1: casa base (2 pisos con rampa), jugador táctil, HUD y guardado.

const WALL_COLOR := Color(0.28, 0.22, 0.2)
const FLOOR_COLOR := Color(0.18, 0.13, 0.1)

var player: Player
var controls: TouchControls
var day_label: Label
var battery_label: Label
var msg_label: Label

func _ready() -> void:
    _build_environment()
    _build_house()
    _build_player()
    _build_hud()
    _show_message("Día %d\nLa puerta se cerró detrás de ti..." % GameState.day, 5.0)

func _build_environment() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color.BLACK
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.25, 0.28, 0.4)
    env.ambient_light_energy = 0.35
    env.fog_enabled = true
    env.fog_light_color = Color(0.03, 0.03, 0.05)
    env.fog_density = 0.05
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)

func _box(pos: Vector3, size: Vector3, color: Color, rot := Vector3.ZERO) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    body.rotation = rot
    var mi := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mi.material_override = mat
    body.add_child(mi)
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    cs.shape = shape
    body.add_child(cs)
    add_child(body)

# Caja definida por esquinas min/max (más fácil para armar la casa)
func _slab(min_p: Vector3, max_p: Vector3, color: Color) -> void:
    _box((min_p + max_p) * 0.5, (max_p - min_p).abs(), color)

func _build_house() -> void:
    # Casa: x -6..6, z -5..5, pisos en y=0 y y=3, techo y=6
    var t := 0.3
    # Suelo planta baja
    _slab(Vector3(-8, -0.2, -7), Vector3(8, 0, 7), FLOOR_COLOR)
    # Paredes exteriores (altura total 6)
    _slab(Vector3(-6 - t, 0, -5 - t), Vector3(6 + t, 6, -5), WALL_COLOR)  # norte
    _slab(Vector3(-6 - t, 0, 5), Vector3(6 + t, 6, 5 + t), WALL_COLOR)    # sur
    _slab(Vector3(-6 - t, 0, -5), Vector3(-6, 6, 5), WALL_COLOR)          # oeste
    _slab(Vector3(6, 0, -5), Vector3(6 + t, 6, 5), WALL_COLOR)            # este
    # Puerta principal (cerrada para siempre hasta romper la maldición)
    _slab(Vector3(-1, 0, 4.7), Vector3(1, 2.4, 5), Color(0.2, 0.1, 0.05))
    # Techo
    _slab(Vector3(-6 - t, 6, -5 - t), Vector3(6 + t, 6.3, 5 + t), WALL_COLOR)
    # Segundo piso con hueco para la rampa (x -5..1, z -4.5..-2.5)
    var y0 := 2.8
    var y1 := 3.0
    _slab(Vector3(-6, y0, -2.5), Vector3(6, y1, 5), FLOOR_COLOR)
    _slab(Vector3(-6, y0, -5), Vector3(6, y1, -4.5), FLOOR_COLOR)
    _slab(Vector3(1, y0, -4.5), Vector3(6, y1, -2.5), FLOOR_COLOR)
    _slab(Vector3(-6, y0, -4.5), Vector3(-5, y1, -2.5), FLOOR_COLOR)
    # Rampa (escalera simple): sube de x=-5 (y=0) a x=1 (y=3)
    var ang := atan2(3.0, 6.0)
    var length := sqrt(36.0 + 9.0)
    _box(Vector3(-2, 1.4, -3.5), Vector3(length, 0.2, 2.0), Color(0.22, 0.16, 0.12), Vector3(0, 0, ang))
    # Pared interior planta baja con puerta (x=3, hueco z 1..3)
    _slab(Vector3(2.85, 0, -5), Vector3(3.15, 2.8, 1), WALL_COLOR)
    _slab(Vector3(2.85, 0, 3), Vector3(3.15, 2.8, 5), WALL_COLOR)
    # Luz tenue de ambiente en la entrada
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(0, 2.5, 2)
    lamp.light_energy = 0.4
    lamp.omni_range = 6.0
    add_child(lamp)

func _build_player() -> void:
    controls = TouchControls.new()
    player = Player.new()
    player.controls = controls
    player.position = Vector3(0, 0.1, 3.5)
    add_child(player)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    layer.add_child(controls)

    day_label = Label.new()
    day_label.text = "Día %d" % GameState.day
    day_label.position = Vector2(24, 16)
    day_label.add_theme_font_size_override("font_size", 28)
    layer.add_child(day_label)

    battery_label = Label.new()
    battery_label.text = "Batería 100%"
    battery_label.position = Vector2(24, 56)
    battery_label.add_theme_font_size_override("font_size", 22)
    layer.add_child(battery_label)
    player.battery_changed.connect(func(v: float): battery_label.text = "Batería %d%%" % int(v))

    var btn := Button.new()
    btn.text = "Linterna"
    btn.custom_minimum_size = Vector2(170, 80)
    btn.add_theme_font_size_override("font_size", 24)
    btn.anchor_left = 1.0
    btn.anchor_right = 1.0
    btn.anchor_top = 1.0
    btn.anchor_bottom = 1.0
    btn.offset_left = -200
    btn.offset_right = -30
    btn.offset_top = -110
    btn.offset_bottom = -30
    btn.pressed.connect(player.toggle_flashlight)
    layer.add_child(btn)

    msg_label = Label.new()
    msg_label.anchor_right = 1.0
    msg_label.anchor_top = 0.35
    msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    msg_label.add_theme_font_size_override("font_size", 34)
    msg_label.modulate.a = 0.0
    layer.add_child(msg_label)

func _show_message(text: String, seconds: float) -> void:
    msg_label.text = text
    var tw := create_tween()
    tw.tween_property(msg_label, "modulate:a", 1.0, 1.0)
    tw.tween_interval(seconds)
    tw.tween_property(msg_label, "modulate:a", 0.0, 1.5)

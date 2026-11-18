extends CharacterBody3D
class_name Player
# Jugador en primera persona con linterna y batería.

signal battery_changed(value: float)

const WALK_SPEED := 2.6
const RUN_SPEED := 4.6
const LOOK_SENS := 0.004
const GRAVITY := 9.8
const BATTERY_SECONDS := 240.0

var controls: TouchControls
var battery := 100.0
var flashlight_on := true

var _head: Node3D
var _cam: Camera3D
var _light: SpotLight3D
var _pitch := 0.0

func _ready() -> void:
    var col := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.7
    col.shape = cap
    col.position.y = 0.85
    add_child(col)

    _head = Node3D.new()
    _head.position.y = 1.6
    add_child(_head)

    _cam = Camera3D.new()
    _cam.fov = 75.0
    _cam.far = 60.0
    _head.add_child(_cam)

    _light = SpotLight3D.new()
    _light.spot_range = 14.0
    _light.spot_angle = 32.0
    _light.light_energy = 3.0
    _head.add_child(_light)

func toggle_flashlight() -> void:
    if battery <= 0.0:
        return
    flashlight_on = not flashlight_on
    _light.visible = flashlight_on

func _physics_process(delta: float) -> void:
    # Mirar
    var look := Vector2.ZERO
    if controls:
        look = controls.consume_look()
    rotate_y(-look.x * LOOK_SENS)
    _pitch = clampf(_pitch - look.y * LOOK_SENS, -1.2, 1.2)
    _head.rotation.x = _pitch

    # Mover (joystick + teclado para probar en PC)
    var dir := Vector2.ZERO
    if controls:
        dir = controls.move_vector
    dir += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    dir = dir.limit_length(1.0)
    var speed := RUN_SPEED if dir.length() > 0.9 else WALK_SPEED
    var move := (transform.basis * Vector3(dir.x, 0, dir.y)) * speed
    velocity.x = move.x
    velocity.z = move.z
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.1
    move_and_slide()

    # Batería
    if flashlight_on:
        battery = maxf(0.0, battery - (100.0 / BATTERY_SECONDS) * delta)
        battery_changed.emit(battery)
        if battery <= 0.0:
            flashlight_on = false
            _light.visible = false
        elif battery < 15.0:
            _light.light_energy = 3.0 * (0.5 + 0.5 * randf())  # parpadeo

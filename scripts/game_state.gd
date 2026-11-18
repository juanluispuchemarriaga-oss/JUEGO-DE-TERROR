extends Node
# Autoload: estado global (día actual, muertes) y guardado.

const SAVE_PATH := "user://save.cfg"
const MAX_DAYS := 3

var day: int = 1
var deaths: int = 0

func _ready() -> void:
    load_game()

func save_game() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("game", "day", day)
    cfg.set_value("game", "deaths", deaths)
    cfg.save(SAVE_PATH)

func load_game() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) == OK:
        day = clampi(int(cfg.get_value("game", "day", 1)), 1, MAX_DAYS)
        deaths = int(cfg.get_value("game", "deaths", 0))

func next_day() -> void:
    day = mini(day + 1, MAX_DAYS)
    save_game()

func register_death() -> void:
    deaths += 1
    save_game()

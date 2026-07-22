extends SceneTree
const Loader=preload("res://game/runtime/content/content_loader.gd")
func _init()->void:
	var loader:=Loader.new();var result:Dictionary=loader.load_and_validate_all();print(JSON.stringify({"suite":"content","ok":result["ok"],"failures":result["errors"]}));loader.free();quit(0 if result["ok"] else 1)

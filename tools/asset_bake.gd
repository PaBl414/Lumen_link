extends SceneTree
func _initialize() -> void:
	var image: Image = Image.create(128,128,false,Image.FORMAT_RGB8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new(); rng.seed = 110011
	for y: int in range(128):
		for x: int in range(128):
			var value: float = rng.randf_range(0.42,0.58); image.set_pixel(x,y,Color(value,value,value,1))
	var error: Error = image.save_png("res://assets/art/grain.png")
	print("grain128x128 seed110011 ",error); quit(0 if error==OK else 1)
